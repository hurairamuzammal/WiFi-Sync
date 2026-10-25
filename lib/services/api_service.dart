import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/device.dart';
import '../models/command.dart';
import '../models/audit_event.dart';
import 'firebase_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _defaultBaseUrl = 'http://127.0.0.1:8000';
  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'user_email';
  static const String _userIdKey = 'user_id';
  static const String _baseUrlKey = 'server_base_url';
  static const String _useFirebaseKey = 'use_firebase_backend';

  String _baseUrl = _defaultBaseUrl;
  String? _token;
  String? _currentUserEmail;
  String? _currentUserId;
  bool _useFirebase = true;

  String get baseUrl => _baseUrl;
  String? get token => _token;
  String? get currentUserEmail =>
      _useFirebase ? (FirebaseService().currentUserEmail ?? _currentUserEmail) : _currentUserEmail;
  String? get currentUserId =>
      _useFirebase ? (FirebaseService().currentUserId ?? _currentUserId) : _currentUserId;
  bool get isAuthenticated =>
      _useFirebase ? (FirebaseService().isAuthenticated || (_token != null && _token!.isNotEmpty)) : (_token != null && _token!.isNotEmpty);
  bool get useFirebase => _useFirebase;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey) ?? _defaultBaseUrl;
    _token = prefs.getString(_tokenKey);
    _currentUserEmail = prefs.getString(_emailKey);
    _currentUserId = prefs.getString(_userIdKey);
    _useFirebase = prefs.getBool(_useFirebaseKey) ?? true;

    if (_useFirebase) {
      await FirebaseService().init();
    }
  }

  Future<void> setUseFirebase(bool value) async {
    _useFirebase = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useFirebaseKey, _useFirebase);
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _baseUrl);
  }

  Map<String, String> _headers({bool requiresAuth = true}) {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth && _token != null) {
      map['Authorization'] = 'Bearer $_token';
    }
    return map;
  }

  // ---------------- Authentication ----------------

  Future<AuthSession> signUp(String email, String password) async {
    if (_useFirebase) {
      try {
        final session = await FirebaseService().signUp(email, password);
        await _saveSession(session);
        return session;
      } catch (e) {
        debugPrint('Firebase signup error: $e');
        if (_baseUrl == _defaultBaseUrl) {
          rethrow;
        }
      }
    }

    final uri = Uri.parse('$_baseUrl/api/v1/auth/signup');
    final resp = await http.post(
      uri,
      headers: _headers(requiresAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (resp.statusCode != 200) {
      final err = _parseError(resp.body);
      throw Exception(err);
    }
    final session = AuthSession.fromJson(jsonDecode(resp.body));
    await _saveSession(session);
    return session;
  }

  Future<AuthSession> logIn(String email, String password) async {
    if (_useFirebase) {
      try {
        final session = await FirebaseService().logIn(email, password);
        await _saveSession(session);
        return session;
      } catch (e) {
        debugPrint('Firebase login error: $e');
        if (_baseUrl == _defaultBaseUrl) {
          rethrow;
        }
      }
    }

    final uri = Uri.parse('$_baseUrl/api/v1/auth/login');
    final resp = await http.post(
      uri,
      headers: _headers(requiresAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (resp.statusCode != 200) {
      final err = _parseError(resp.body);
      throw Exception(err);
    }
    final session = AuthSession.fromJson(jsonDecode(resp.body));
    await _saveSession(session);
    return session;
  }

  Future<AuthSession> signInWithGoogle({bool isSignUp = false}) async {
    final session = await FirebaseService().signInWithGoogle(isSignUp: isSignUp);
    await _saveSession(session);
    return session;
  }

  Future<AuthSession> signUpWithGoogle() =>
      signInWithGoogle(isSignUp: true);

  Future<void> sendPasswordResetEmail(String email) async {
    await FirebaseService().sendPasswordResetEmail(email);
  }

  /// Clears local saved session, tokens, and disconnects clipboard sync (Forget Me / Forget Session).
  Future<void> forgetDeviceSession() async {
    await logOut();
  }

  bool get isEmailPasswordAccount => FirebaseService().isEmailPasswordAccount;

  Future<void> logOut() async {
    if (_useFirebase) {
      await FirebaseService().logOut();
    }
    _token = null;
    _currentUserEmail = null;
    _currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_userIdKey);
  }

  Future<void> _saveSession(AuthSession session) async {
    _token = session.accessToken;
    _currentUserEmail = session.email;
    _currentUserId = session.userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.accessToken);
    await prefs.setString(_emailKey, session.email);
    await prefs.setString(_userIdKey, session.userId);
  }

  // ---------------- Devices ----------------

  Future<List<Device>> getDevices({bool includeRevoked = false}) async {
    if (_useFirebase && FirebaseService().isAuthenticated) {
      try {
        final devices = await FirebaseService().devicesStream().first;
        if (!includeRevoked) {
          return devices.where((d) => !d.isRevoked).toList();
        }
        return devices;
      } catch (e) {
        debugPrint('Firebase getDevices fallback: $e');
      }
    }

    final uri = Uri.parse('$_baseUrl/api/v1/devices?include_revoked=$includeRevoked');
    final resp = await http.get(uri, headers: _headers());
    if (resp.statusCode != 200) {
      throw Exception(_parseError(resp.body));
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.map((item) => Device.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Device> registerDevice({
    required String displayName,
    required String platform,
  }) async {
    if (_useFirebase && FirebaseService().isAuthenticated) {
      return await FirebaseService().registerDevice(
        displayName: displayName,
        platform: platform,
      );
    }

    final uri = Uri.parse('$_baseUrl/api/v1/devices');
    final resp = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'display_name': displayName,
        'platform': platform,
        'agent_version': '1.0.0',
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception(_parseError(resp.body));
    }
    return Device.fromJson(jsonDecode(resp.body));
  }

  Future<Device> updateDevice(
    String deviceId, {
    String? displayName,
    bool? clipboardSyncEnabled,
  }) async {
    if (_useFirebase && FirebaseService().isAuthenticated) {
      return await FirebaseService().updateDevice(
        deviceId,
        displayName: displayName,
        clipboardSyncEnabled: clipboardSyncEnabled,
      );
    }

    final uri = Uri.parse('$_baseUrl/api/v1/devices/$deviceId');
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (clipboardSyncEnabled != null) {
      body['clipboard_sync_enabled'] = clipboardSyncEnabled;
    }

    final resp = await http.patch(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) {
      throw Exception(_parseError(resp.body));
    }
    return Device.fromJson(jsonDecode(resp.body));
  }

  Future<void> revokeDevice(String deviceId) async {
    if (_useFirebase && FirebaseService().isAuthenticated) {
      return await FirebaseService().revokeDevice(deviceId);
    }

    final uri = Uri.parse('$_baseUrl/api/v1/devices/$deviceId');
    final resp = await http.delete(uri, headers: _headers());
    if (resp.statusCode != 200) {
      throw Exception(_parseError(resp.body));
    }
  }

  // ---------------- Pairing ----------------

  Future<String> requestPairingCode() async {
    if (_useFirebase && FirebaseService().isAuthenticated) {
      return await FirebaseService().requestPairingCode();
    }

    final uri = Uri.parse('$_baseUrl/api/v1/devices/pair/request');
    final resp = await http.post(uri, headers: _headers());
    if (resp.statusCode != 200) {
      throw Exception(_parseError(resp.body));
    }
    final data = jsonDecode(resp.body);
    return data['code'] as String;
  }

  // ---------------- Commands ----------------

  Future<DeviceCommand> sendCommand({
    required String deviceId,
    required String action,
    int ttlSeconds = 60,
  }) async {
    if (_useFirebase && FirebaseService().isAuthenticated) {
      return await FirebaseService().sendCommand(
        deviceId: deviceId,
        action: action,
        ttlSeconds: ttlSeconds,
      );
    }

    final uri = Uri.parse('$_baseUrl/api/v1/commands');
    final resp = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'device_id': deviceId,
        'action': action,
        'ttl_seconds': ttlSeconds,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception(_parseError(resp.body));
    }
    return DeviceCommand.fromJson(jsonDecode(resp.body));
  }

  Future<List<DeviceCommand>> getCommands() async {
    if (_useFirebase && FirebaseService().isAuthenticated) {
      try {
        return await FirebaseService().commandsStream().first;
      } catch (e) {
        debugPrint('Firebase getCommands fallback: $e');
      }
    }

    final uri = Uri.parse('$_baseUrl/api/v1/commands?limit=50');
    final resp = await http.get(uri, headers: _headers());
    if (resp.statusCode != 200) {
      throw Exception(_parseError(resp.body));
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.map((item) => DeviceCommand.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> cancelCommand(String commandId) async {
    if (_useFirebase && FirebaseService().isAuthenticated) {
      return await FirebaseService().cancelCommand(commandId);
    }

    final uri = Uri.parse('$_baseUrl/api/v1/commands/$commandId/cancel');
    final resp = await http.post(uri, headers: _headers());
    if (resp.statusCode != 200) {
      throw Exception(_parseError(resp.body));
    }
  }

  // ---------------- Audit Events ----------------

  Future<List<AuditEvent>> getAuditEvents() async {
    final uri = Uri.parse('$_baseUrl/api/v1/audit?limit=50');
    final resp = await http.get(uri, headers: _headers());
    if (resp.statusCode != 200) {
      throw Exception(_parseError(resp.body));
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.map((item) => AuditEvent.fromJson(item as Map<String, dynamic>)).toList();
  }

  // ---------------- Clipboard Sync ----------------

  Future<void> sendClipboardText({
    required String sourceDeviceId,
    required String text,
    required String eventId,
  }) async {
    if (_useFirebase && FirebaseService().isAuthenticated) {
      return await FirebaseService().sendClipboardText(
        sourceDeviceId: sourceDeviceId,
        text: text,
        eventId: eventId,
      );
    }

    final uri = Uri.parse('$_baseUrl/api/v1/clipboard');
    final resp = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'event_id': eventId,
        'source_device_id': sourceDeviceId,
        'text': text,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception(_parseError(resp.body));
    }
  }

  String _parseError(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map && json.containsKey('detail')) {
        return json['detail'].toString();
      }
    } catch (_) {}
    return 'Operation failed: $body';
  }
}
