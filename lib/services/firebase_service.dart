import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import '../models/user.dart' as app_models;
import '../models/device.dart';
import '../models/command.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  static const String _useEmulatorKey = 'use_firebase_emulator';
  static const String _emulatorHostKey = 'firebase_emulator_host';
  static const String _restIdTokenKey = 'fb_rest_id_token';
  static const String _restRefreshTokenKey = 'fb_rest_refresh_token';
  static const String _restUidKey = 'fb_rest_uid';
  static const String _restEmailKey = 'fb_rest_email';
  static const String _restProviderKey = 'fb_rest_provider';

  bool _initialized = false;
  bool _useEmulator = false;
  String _emulatorHost = '127.0.0.1';

  FirebaseAuth? _auth;
  FirebaseDatabase? _database;

  // Linux Desktop REST fallback state (since firebase_database has no native Linux plugin)
  final http.Client _httpClient = http.Client();
  String? _restIdToken;
  String? _restRefreshToken;
  String? _restUid;
  String? _restEmail;
  String _restProvider = 'password';
  String? _lastSeenClipboardKey;

  bool get _useRestClient =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  String get _apiKey => DefaultFirebaseOptions.linux.apiKey;
  String get _rtdbBaseUrl =>
      (DefaultFirebaseOptions.linux.databaseURL ??
              'https://world-of-iot-hub-default-rtdb.firebaseio.com')
          .replaceAll(RegExp(r'/+$'), '');

  bool get isInitialized => _initialized;
  bool get useEmulator => _useEmulator;
  String get emulatorHost => _emulatorHost;

  User? get currentFirebaseUser => _auth?.currentUser;
  String? get currentUserId =>
      _useRestClient ? _restUid : _auth?.currentUser?.uid;
  String? get currentUserEmail =>
      _useRestClient ? _restEmail : _auth?.currentUser?.email;
  bool get isAuthenticated => _useRestClient
      ? (_restUid != null && _restIdToken != null)
      : (_auth?.currentUser != null);

  /// Returns true ONLY if the signed-in account uses Email & Password (not Google OAuth).
  bool get isEmailPasswordAccount {
    if (_useRestClient) {
      return _restProvider == 'password';
    }
    final user = _auth?.currentUser;
    if (user == null) return true;
    if (user.providerData.isEmpty) return true;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _useEmulator = prefs.getBool(_useEmulatorKey) ?? false;
      _emulatorHost = prefs.getString(_emulatorHostKey) ?? '127.0.0.1';

      if (_useRestClient) {
        _restIdToken = prefs.getString(_restIdTokenKey);
        _restRefreshToken = prefs.getString(_restRefreshTokenKey);
        _restUid = prefs.getString(_restUidKey);
        _restEmail = prefs.getString(_restEmailKey);
        _restProvider = prefs.getString(_restProviderKey) ?? 'password';
        if (_restRefreshToken != null && _restRefreshToken!.isNotEmpty) {
          await _refreshRestToken();
        }
        _initialized = true;
        return;
      }

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      _auth = FirebaseAuth.instance;
      _database = FirebaseDatabase.instance;

      if (_useEmulator) {
        try {
          _auth?.useAuthEmulator(_emulatorHost, 9099);
          _database?.useDatabaseEmulator(_emulatorHost, 9000);
        } catch (_) {}
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Firebase initialization note: $e');
    }
  }

  Future<void> _saveRestSession({
    required String idToken,
    required String refreshToken,
    required String uid,
    required String email,
    String provider = 'password',
  }) async {
    _restIdToken = idToken;
    _restRefreshToken = refreshToken;
    _restUid = uid;
    _restEmail = email;
    _restProvider = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_restIdTokenKey, idToken);
    await prefs.setString(_restRefreshTokenKey, refreshToken);
    await prefs.setString(_restUidKey, uid);
    await prefs.setString(_restEmailKey, email);
    await prefs.setString(_restProviderKey, provider);
  }

  Future<void> _refreshRestToken() async {
    if (_restRefreshToken == null || _restRefreshToken!.isEmpty) return;
    try {
      final resp = await http.post(
        Uri.parse('https://securetoken.googleapis.com/v1/token?key=$_apiKey'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'grant_type=refresh_token&refresh_token=$_restRefreshToken',
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _restIdToken = data['id_token'] as String?;
        _restRefreshToken =
            (data['refresh_token'] as String?) ?? _restRefreshToken;
        _restUid = (data['user_id'] as String?) ?? _restUid;
        final prefs = await SharedPreferences.getInstance();
        if (_restIdToken != null) {
          await prefs.setString(_restIdTokenKey, _restIdToken!);
        }
        if (_restRefreshToken != null) {
          await prefs.setString(_restRefreshTokenKey, _restRefreshToken!);
        }
      }
    } catch (e) {
      debugPrint('REST token refresh note: $e');
    }
  }

  Uri _rtdbUri(String path) {
    final clean = path.replaceAll(RegExp(r'^/+'), '');
    return Uri.parse('$_rtdbBaseUrl/$clean.json?auth=$_restIdToken');
  }

  Future<dynamic> _restGet(String path) async {
    var resp = await _httpClient.get(_rtdbUri(path));
    if (resp.statusCode == 401) {
      await _refreshRestToken();
      resp = await _httpClient.get(_rtdbUri(path));
    }
    if (resp.statusCode >= 400) {
      throw Exception('RTDB GET failed (${resp.statusCode}): ${resp.body}');
    }
    if (resp.body.isEmpty || resp.body == 'null') return null;
    return jsonDecode(resp.body);
  }

  Future<void> _restPut(String path, Map<String, dynamic> payload) async {
    var resp = await _httpClient.put(
      _rtdbUri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (resp.statusCode == 401) {
      await _refreshRestToken();
      resp = await _httpClient.put(
        _rtdbUri(path),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    }
    if (resp.statusCode >= 400) {
      throw Exception('RTDB PUT failed (${resp.statusCode}): ${resp.body}');
    }
  }

  Future<void> _restPatch(String path, Map<String, dynamic> payload) async {
    var resp = await _httpClient.patch(
      _rtdbUri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (resp.statusCode == 401) {
      await _refreshRestToken();
      resp = await _httpClient.patch(
        _rtdbUri(path),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    }
    if (resp.statusCode >= 400) {
      throw Exception('RTDB PATCH failed (${resp.statusCode}): ${resp.body}');
    }
  }

  Future<void> setUseEmulator(bool value, {String? host}) async {
    _useEmulator = value;
    if (host != null) _emulatorHost = host;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useEmulatorKey, _useEmulator);
    await prefs.setString(_emulatorHostKey, _emulatorHost);
  }

  DatabaseReference? _userRef() {
    final uid = currentUserId;
    if (uid == null || _database == null) return null;
    return _database!.ref('users/$uid');
  }

  // ---------------- Authentication ----------------

  Future<app_models.AuthSession> signUp(String email, String password) async {
    if (!_initialized) await init();

    if (_useRestClient) {
      final resp = await http.post(
        Uri.parse(
            'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
          'returnSecureToken': true,
        }),
      );
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode != 200) {
        final msg = (body['error'] as Map?)?['message'] ?? 'Sign up failed';
        throw Exception(msg);
      }
      final idToken = body['idToken'] as String;
      final refreshToken = body['refreshToken'] as String? ?? '';
      final uid = body['localId'] as String;
      final userEmail = body['email'] as String? ?? email.trim();
      await _saveRestSession(
        idToken: idToken,
        refreshToken: refreshToken,
        uid: uid,
        email: userEmail,
      );
      await _restPut('users/$uid/profile', {
        'email': userEmail,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      await recordAuditEvent('user_signup', metadata: {'email': userEmail});
      return app_models.AuthSession(
        accessToken: idToken,
        tokenType: 'bearer',
        userId: uid,
        email: userEmail,
      );
    }

    final cred = await _auth!.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final user = cred.user!;

    final ref = _database?.ref('users/${user.uid}/profile');
    await ref?.set({
      'email': user.email,
      'createdAt': ServerValue.timestamp,
    });

    await recordAuditEvent('user_signup', metadata: {'email': user.email});

    return app_models.AuthSession(
      accessToken: await user.getIdToken() ?? 'session-token',
      tokenType: 'bearer',
      userId: user.uid,
      email: user.email ?? '',
    );
  }

  Future<app_models.AuthSession> logIn(String email, String password) async {
    if (!_initialized) await init();

    if (_useRestClient) {
      final resp = await http.post(
        Uri.parse(
            'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
          'returnSecureToken': true,
        }),
      );
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode != 200) {
        final msg = (body['error'] as Map?)?['message'] ?? 'Sign in failed';
        throw Exception(msg);
      }
      final idToken = body['idToken'] as String;
      final refreshToken = body['refreshToken'] as String? ?? '';
      final uid = body['localId'] as String;
      final userEmail = body['email'] as String? ?? email.trim();
      await _saveRestSession(
        idToken: idToken,
        refreshToken: refreshToken,
        uid: uid,
        email: userEmail,
      );
      await recordAuditEvent('user_login', metadata: {'email': userEmail});
      return app_models.AuthSession(
        accessToken: idToken,
        tokenType: 'bearer',
        userId: uid,
        email: userEmail,
      );
    }

    final cred = await _auth!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final user = cred.user!;
    await recordAuditEvent('user_login', metadata: {'email': user.email});

    return app_models.AuthSession(
      accessToken: await user.getIdToken() ?? 'session-token',
      tokenType: 'bearer',
      userId: user.uid,
      email: user.email ?? '',
    );
  }

  Future<app_models.AuthSession> signInWithGoogle({bool isSignUp = false}) async {
    if (!_initialized) await init();

    if (_useRestClient) {
      throw Exception(
        'On Linux Desktop, please sign in with Email & Password (huraira.eqeel@gmail.com) or use Google Sign-In on your Samsung Android phone.',
      );
    }

    final googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.setCustomParameters({'prompt': 'select_account'});

    final UserCredential cred;
    if (kIsWeb) {
      cred = await _auth!.signInWithPopup(googleProvider);
    } else {
      cred = await _auth!.signInWithProvider(googleProvider);
    }

    final user = cred.user!;
    final ref = _database?.ref('users/${user.uid}/profile');
    await ref?.update({
      'email': user.email,
      'displayName': user.displayName,
      'authProvider': 'google.com',
      'lastLoginAt': ServerValue.timestamp,
    });

    final eventType = isSignUp ? 'user_google_signup' : 'user_google_login';
    await recordAuditEvent(eventType, metadata: {'email': user.email});

    return app_models.AuthSession(
      accessToken: await user.getIdToken() ?? 'session-token',
      tokenType: 'bearer',
      userId: user.uid,
      email: user.email ?? '',
    );
  }

  Future<app_models.AuthSession> signUpWithGoogle() =>
      signInWithGoogle(isSignUp: true);

  /// Sends a password reset email ONLY for Email/Password accounts.
  /// Rejects accounts that are registered exclusively with Google OAuth.
  Future<void> sendPasswordResetEmail(String email) async {
    if (!_initialized) await init();
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      throw Exception('Please enter your email address first.');
    }

    // If the user is currently logged in with this email via Google only, block password reset
    if (isAuthenticated &&
        currentUserEmail?.toLowerCase() == cleanEmail.toLowerCase() &&
        !isEmailPasswordAccount) {
      throw Exception(
        'This account uses Google Sign-In. Password reset is only available for email/password accounts.',
      );
    }

    // Query Firebase IdentityToolkit createAuthUri to check provider for this email
    try {
      final checkResp = await http.post(
        Uri.parse(
            'https://identitytoolkit.googleapis.com/v1/accounts:createAuthUri?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': cleanEmail,
          'continueUri': 'https://world-of-iot-hub.firebaseapp.com',
        }),
      );
      if (checkResp.statusCode == 200) {
        final data = jsonDecode(checkResp.body) as Map<String, dynamic>;
        final providers = (data['allProviders'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        if (providers.isNotEmpty && !providers.contains('password')) {
          throw Exception(
            'This email is linked to Google Sign-In only. Password reset is only available for email/password accounts.',
          );
        }
      }
    } catch (e) {
      if (e.toString().contains('Google Sign-In')) rethrow;
    }

    if (_useRestClient) {
      final resp = await http.post(
        Uri.parse(
            'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestType': 'PASSWORD_RESET',
          'email': cleanEmail,
        }),
      );
      if (resp.statusCode != 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final msg =
            (body['error'] as Map?)?['message'] ?? 'Password reset failed';
        throw Exception(msg);
      }
      return;
    }

    await _auth!.sendPasswordResetEmail(email: cleanEmail);
  }

  Future<void> logOut() async {
    if (_useRestClient) {
      _restIdToken = null;
      _restRefreshToken = null;
      _restUid = null;
      _restEmail = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_restIdTokenKey);
      await prefs.remove(_restRefreshTokenKey);
      await prefs.remove(_restUidKey);
      await prefs.remove(_restEmailKey);
      return;
    }
    await _auth?.signOut();
  }

  // ---------------- Devices (Real-Time Streams & Actions) ----------------

  List<Device> _parseDevicesMap(Map<dynamic, dynamic> data) {
    final bool isLinuxHost =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
    final bool isAndroidHost =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final bool isIOSHost =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    final byKey = <String, Device>{};
    data.forEach((key, val) {
      if (val is Map) {
        final devId = key.toString();
        if (devId == 'linux-thinkpad-ui') {
          return;
        }
        final map = Map<String, dynamic>.from(val);
        final platform =
            (map['platform'] as String? ?? 'linux').toLowerCase();

        // Peer-only visibility: each device sees OTHER paired devices, never itself.
        if (isLinuxHost && platform == 'linux') return;
        if (isAndroidHost && platform == 'android') return;
        if (isIOSHost && platform == 'ios') return;

        final lastSeen = map['lastSeenAt'];
        final isRevoked = map['revoked'] == true;

        String status = 'offline';
        if (!isRevoked && lastSeen is num && lastSeen > 0) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - lastSeen < 45000) {
            status = 'online';
          }
        }

        final device = Device(
          id: devId,
          userId: currentUserId ?? '',
          displayName: map['displayName'] as String? ?? 'Device',
          platform: platform,
          agentVersion: map['agentVersion'] as String?,
          createdAt: map['createdAt']?.toString() ?? '',
          lastSeenAt: (lastSeen is num && lastSeen > 0)
              ? DateTime.fromMillisecondsSinceEpoch(lastSeen.toInt())
                  .toIso8601String()
              : null,
          status: status,
          revokedAt: isRevoked ? 'revoked' : null,
          clipboardSyncEnabled: map['clipboardSyncEnabled'] == true,
        );

        // Deduplicate per platform primary node so duplicate entries never appear
        final dedupKey = platform == 'linux'
            ? 'linux_primary'
            : (platform == 'android' ? 'android_primary' : devId);
        final existing = byKey[dedupKey];
        if (existing == null ||
            devId == 'linux-thinkpad' ||
            devId == 'android-sm-a346e' ||
            (device.isOnline && !existing.isOnline)) {
          byKey[dedupKey] = device;
        }
      }
    });
    return byKey.values.toList();
  }

  Stream<List<Device>> devicesStream() {
    if (_useRestClient) {
      final uid = currentUserId;
      if (uid == null) return Stream.value([]);
      Stream<List<Device>> generator() async* {
        while (currentUserId == uid) {
          try {
            final raw = await _restGet('users/$uid/devices');
            if (raw is Map) {
              yield _parseDevicesMap(raw);
            } else {
              yield <Device>[];
            }
          } catch (_) {}
          await Future.delayed(const Duration(milliseconds: 2500));
        }
      }

      return generator().asBroadcastStream();
    }

    final ref = _userRef()?.child('devices');
    if (ref == null) return Stream.value([]);

    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return [];
      final data = snapshot.value as Map<dynamic, dynamic>;
      return _parseDevicesMap(data);
    });
  }

  Future<Device> registerDevice({
    required String displayName,
    required String platform,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');
    final now = DateTime.now().millisecondsSinceEpoch;
    final deviceId = platform.toLowerCase() == 'linux'
        ? 'linux-thinkpad'
        : 'dev_${now}_${Random().nextInt(9999)}';

    final deviceData = {
      'displayName': displayName,
      'platform': platform.toLowerCase(),
      'agentVersion': '2.1.0',
      'trusted': true,
      'revoked': false,
      'clipboardSyncEnabled': true,
      'lastSeenAt': now,
      'createdAt': now,
    };

    if (_useRestClient) {
      await _restPatch('users/$uid/devices/$deviceId', deviceData);
      await recordAuditEvent('device_registered',
          deviceId: deviceId, metadata: {'displayName': displayName});
      return Device(
        id: deviceId,
        userId: uid,
        displayName: displayName,
        platform: platform,
        createdAt: DateTime.fromMillisecondsSinceEpoch(now).toIso8601String(),
        lastSeenAt: DateTime.fromMillisecondsSinceEpoch(now).toIso8601String(),
        status: 'online',
        clipboardSyncEnabled: true,
      );
    }

    final ref = _userRef()?.child('devices/$deviceId');
    if (ref == null) throw Exception('User not authenticated');

    await ref.update(deviceData);
    await recordAuditEvent('device_registered',
        deviceId: deviceId, metadata: {'displayName': displayName});

    return Device(
      id: deviceId,
      userId: uid,
      displayName: displayName,
      platform: platform,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now).toIso8601String(),
      lastSeenAt: DateTime.fromMillisecondsSinceEpoch(now).toIso8601String(),
      status: 'online',
      clipboardSyncEnabled: true,
    );
  }

  Future<void> upsertClientDevicePresence({
    required String deviceId,
    required String displayName,
    required String platform,
    bool online = true,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;
    final now = online ? DateTime.now().millisecondsSinceEpoch : 0;
    final payload = {
      'displayName': displayName,
      'platform': platform.toLowerCase(),
      'agentVersion': '2.1.0',
      'trusted': true,
      'revoked': false,
      'clipboardSyncEnabled': true,
      'lastSeenAt': now,
    };

    if (_useRestClient) {
      await _restPatch('users/$uid/devices/$deviceId', payload);
      return;
    }

    final ref = _userRef()?.child('devices/$deviceId');
    if (ref == null) return;
    if (online) {
      try {
        await ref.onDisconnect().update({'lastSeenAt': 0});
      } catch (_) {}
    }
    await ref.update(payload);
  }

  Future<Device> updateDevice(
    String deviceId, {
    String? displayName,
    bool? clipboardSyncEnabled,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (clipboardSyncEnabled != null) {
      updates['clipboardSyncEnabled'] = clipboardSyncEnabled;
    }

    if (_useRestClient) {
      await _restPatch('users/$uid/devices/$deviceId', updates);
      final raw = await _restGet('users/$uid/devices/$deviceId');
      final val = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      return Device(
        id: deviceId,
        userId: uid,
        displayName: val['displayName'] ?? '',
        platform: val['platform'] ?? 'linux',
        agentVersion: val['agentVersion'],
        createdAt: val['createdAt']?.toString() ?? '',
        lastSeenAt: val['lastSeenAt']?.toString(),
        status: val['revoked'] == true ? 'offline' : 'online',
        clipboardSyncEnabled: val['clipboardSyncEnabled'] == true,
      );
    }

    final ref = _userRef()?.child('devices/$deviceId');
    if (ref == null) throw Exception('User not authenticated');

    await ref.update(updates);
    final snapshot = await ref.get();
    final val = Map<String, dynamic>.from(snapshot.value as Map);

    return Device(
      id: deviceId,
      userId: uid,
      displayName: val['displayName'] ?? '',
      platform: val['platform'] ?? 'linux',
      agentVersion: val['agentVersion'],
      createdAt: val['createdAt']?.toString() ?? '',
      lastSeenAt: val['lastSeenAt']?.toString(),
      status: val['revoked'] == true ? 'offline' : 'online',
      clipboardSyncEnabled: val['clipboardSyncEnabled'] == true,
    );
  }

  Future<void> revokeDevice(String deviceId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    if (_useRestClient) {
      await _restPatch('users/$uid/devices/$deviceId', {
        'revoked': true,
        'trusted': false,
      });
      await recordAuditEvent('device_revoked', deviceId: deviceId);
      return;
    }

    final ref = _userRef()?.child('devices/$deviceId');
    if (ref == null) throw Exception('User not authenticated');

    await ref.update({
      'revoked': true,
      'trusted': false,
    });
    await recordAuditEvent('device_revoked', deviceId: deviceId);
  }

  // ---------------- Pairing (US-08) ----------------

  Future<String> requestPairingCode() async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    final code = (100000 + (DateTime.now().microsecond % 900000)).toString();
    final now = DateTime.now().millisecondsSinceEpoch;
    final expires = now + (5 * 60 * 1000);

    if (_useRestClient) {
      final reqId = 'pair_$now';
      await _restPut('users/$uid/pairingRequests/$reqId', {
        'code': code,
        'status': 'pending',
        'createdAt': now,
        'expiresAt': expires,
      });
      return code;
    }

    final ref = _userRef()?.child('pairingRequests');
    if (ref == null) throw Exception('User not authenticated');

    final newReq = ref.push();
    await newReq.set({
      'code': code,
      'status': 'pending',
      'createdAt': now,
      'expiresAt': expires,
    });

    return code;
  }

  // ---------------- Commands (US-16, 17, 18, 19, 20) ----------------

  List<DeviceCommand> _parseCommandsMap(Map<dynamic, dynamic> data) {
    final list = <DeviceCommand>[];
    data.forEach((key, val) {
      if (val is Map) {
        final map = Map<String, dynamic>.from(val);
        list.add(DeviceCommand(
          id: key.toString(),
          userId: currentUserId ?? '',
          deviceId: map['targetDeviceId'] as String? ?? '',
          action: map['action'] as String? ?? '',
          status: map['status'] as String? ?? 'pending',
          createdAt: map['createdAt']?.toString() ?? '',
          expiresAt: map['expiresAt']?.toString() ?? '',
          acceptedAt: map['acceptedAt']?.toString(),
          finishedAt: map['finishedAt']?.toString(),
          errorCode: map['errorCode']?.toString(),
          resultSummary: map['resultSummary'] as String?,
        ));
      }
    });
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Stream<List<DeviceCommand>> commandsStream() {
    if (_useRestClient) {
      final uid = currentUserId;
      if (uid == null) return Stream.value([]);
      return Stream.periodic(const Duration(seconds: 3), (i) => i)
          .asyncMap((_) async {
        try {
          final raw = await _restGet('users/$uid/commands');
          if (raw is Map) {
            return _parseCommandsMap(raw);
          }
        } catch (_) {}
        return <DeviceCommand>[];
      }).asBroadcastStream();
    }

    final ref = _userRef()?.child('commands');
    if (ref == null) return Stream.value([]);

    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return [];
      final data = snapshot.value as Map<dynamic, dynamic>;
      return _parseCommandsMap(data);
    });
  }

  Future<DeviceCommand> sendCommand({
    required String deviceId,
    required String action,
    int ttlSeconds = 60,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    final now = DateTime.now().millisecondsSinceEpoch;
    final expires = now + (ttlSeconds * 1000);
    final data = {
      'targetDeviceId': deviceId,
      'action': action,
      'status': 'pending',
      'createdAt': now,
      'expiresAt': expires,
    };

    if (_useRestClient) {
      final cmdId = 'cmd_${now}_${Random().nextInt(9999)}';
      await _restPut('users/$uid/commands/$cmdId', data);
      await recordAuditEvent('command_created',
          deviceId: deviceId, commandId: cmdId, metadata: {'action': action});
      return DeviceCommand(
        id: cmdId,
        userId: uid,
        deviceId: deviceId,
        action: action,
        status: 'pending',
        createdAt: DateTime.fromMillisecondsSinceEpoch(now).toIso8601String(),
        expiresAt:
            DateTime.fromMillisecondsSinceEpoch(expires).toIso8601String(),
      );
    }

    final ref = _userRef()?.child('commands');
    if (ref == null) throw Exception('User not authenticated');

    final newCmd = ref.push();
    final cmdId = newCmd.key!;

    await newCmd.set(data);
    await recordAuditEvent('command_created',
        deviceId: deviceId, commandId: cmdId, metadata: {'action': action});

    return DeviceCommand(
      id: cmdId,
      userId: uid,
      deviceId: deviceId,
      action: action,
      status: 'pending',
      createdAt: DateTime.fromMillisecondsSinceEpoch(now).toIso8601String(),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expires).toIso8601String(),
    );
  }

  Future<void> cancelCommand(String commandId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    if (_useRestClient) {
      await _restPatch('users/$uid/commands/$commandId', {
        'status': 'cancelled',
        'finishedAt': DateTime.now().millisecondsSinceEpoch,
      });
      await recordAuditEvent('command_cancelled', commandId: commandId);
      return;
    }

    final ref = _userRef()?.child('commands/$commandId');
    if (ref == null) throw Exception('User not authenticated');

    await ref.update({
      'status': 'cancelled',
      'finishedAt': DateTime.now().millisecondsSinceEpoch,
    });
    await recordAuditEvent('command_cancelled', commandId: commandId);
  }

  // ---------------- Clipboard Sync (US-12, 13, 14) ----------------

  Stream<Map<String, dynamic>?> _linuxClipboardSseStream(String uid) async* {
    bool initialSeeded = false;
    while (isAuthenticated && currentUserId == uid) {
      final sseClient = http.Client();
      try {
        final req = http.Request(
          'GET',
          _rtdbUri('users/$uid/clipboardEvents/latest'),
        )..headers['Accept'] = 'text/event-stream';
        final streamed = await sseClient.send(req);
        if (streamed.statusCode == 401) {
          await _refreshRestToken();
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
        String eventType = '';
        await for (final line in streamed.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (line.startsWith('event:')) {
            eventType = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            final rawData = line.substring(5).trim();
            if ((eventType == 'put' || eventType == 'patch') &&
                rawData.isNotEmpty &&
                rawData != 'null') {
              final decoded = jsonDecode(rawData);
              if (decoded is Map && decoded['data'] is Map) {
                final map = Map<String, dynamic>.from(decoded['data'] as Map);
                final key = map['createdAt']?.toString();
                if (!initialSeeded) {
                  initialSeeded = true;
                  _lastSeenClipboardKey = key;
                } else if (key != null && key != _lastSeenClipboardKey) {
                  _lastSeenClipboardKey = key;
                  yield map;
                }
              }
            }
          }
        }
      } catch (_) {
        await Future.delayed(const Duration(seconds: 1));
      } finally {
        sseClient.close();
      }
    }
  }

  Stream<Map<String, dynamic>?> clipboardStream() {
    if (_useRestClient) {
      final uid = currentUserId;
      if (uid == null) return Stream.value(null);
      return _linuxClipboardSseStream(uid).asBroadcastStream();
    }

    final ref = _userRef()?.child('clipboardEvents/latest');
    if (ref == null) return Stream.value(null);

    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null || snapshot.value is! Map) {
        return null;
      }
      return Map<String, dynamic>.from(snapshot.value as Map);
    });
  }

  Future<void> sendClipboardText({
    required String sourceDeviceId,
    required String text,
    required String eventId,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    final now = DateTime.now().millisecondsSinceEpoch;
    final expires = now + (60 * 1000);
    final payload = {
      'eventId': eventId,
      'sourceDeviceId': sourceDeviceId,
      'text': text,
      'createdAt': now,
      'expiresAt': expires,
    };

    if (_useRestClient) {
      _lastSeenClipboardKey = now.toString();
      await _restPut('users/$uid/clipboardEvents/latest', payload);
      return;
    }

    final ref = _userRef()?.child('clipboardEvents/latest');
    if (ref == null) throw Exception('User not authenticated');
    await ref.set(payload);
  }

  // ---------------- Audit Events (US-23) ----------------

  Future<void> recordAuditEvent(
    String eventType, {
    String? deviceId,
    String? commandId,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (_useRestClient) {
      final evtId = 'audit_${now}_${Random().nextInt(9999)}';
      try {
        await _restPut('users/$uid/auditEvents/$evtId', {
          'eventType': eventType,
          'deviceId': deviceId,
          'commandId': commandId,
          'createdAt': now,
          'metadata': metadata ?? {},
        });
      } catch (_) {}
      return;
    }

    final ref = _userRef()?.child('auditEvents');
    if (ref == null) return;

    final newEvt = ref.push();
    await newEvt.set({
      'eventType': eventType,
      'deviceId': deviceId,
      'commandId': commandId,
      'createdAt': now,
      'metadata': metadata ?? {},
    });
  }
}
