import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/device.dart';
import 'api_service.dart';
import 'background_sync_service.dart';
import 'firebase_service.dart';

class ClipboardSyncItem {
  final String text;
  final String sourceDeviceId;
  final DateTime timestamp;
  final bool isIncoming;

  ClipboardSyncItem({
    required this.text,
    required this.sourceDeviceId,
    required this.timestamp,
    required this.isIncoming,
  });
}

/// Global V2 Seamless Clipboard & Presence Sync Manager.
///
/// - Automatically joins/heartbeats the current mobile/desktop client device on Wi-Fi
/// - Automatically watches the local clipboard and pushes changes to Firebase RTDB
/// - Automatically receives remote clipboard events, sets local clipboard, plays a
///   subtle "dink" + haptic feedback, triggers a compact Samsung-style pill snackbar,
///   and lights up the top-right AppBar indicator icon.
class ClipboardSyncManager extends ChangeNotifier with WidgetsBindingObserver {
  static final ClipboardSyncManager _instance =
      ClipboardSyncManager._internal();
  factory ClipboardSyncManager() => _instance;
  ClipboardSyncManager._internal();

  bool _running = false;
  bool _autoSyncEnabled = true;
  bool _hasUnreadClip = false;
  int _unreadCount = 0;

  String? _lastKnownClipboardText;
  String? _lastEventKey;
  int _startedAtMs = 0;
  final List<ClipboardSyncItem> _history = [];
  List<Device> _onlineDevices = [];

  Timer? _clipboardWatchTimer;
  Timer? _heartbeatTimer;
  StreamSubscription<Map<String, dynamic>?>? _remoteClipSub;
  StreamSubscription<List<Device>>? _devicesSub;

  /// Callback invoked whenever a new remote clipboard item arrives so the active
  /// screen can show a compact Samsung-style floating pill snackbar.
  void Function(ClipboardSyncItem item)? onRemoteClipReceived;

  bool get autoSyncEnabled => _autoSyncEnabled;
  bool get hasUnreadClip => _hasUnreadClip;
  int get unreadCount => _unreadCount;
  List<ClipboardSyncItem> get history => List.unmodifiable(_history);
  ClipboardSyncItem? get latestItem =>
      _history.isNotEmpty ? _history.first : null;
  List<Device> get onlineDevices => _onlineDevices;

  String get localDeviceId {
    if (kIsWeb) return 'web-client';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android-sm-a346e';
      case TargetPlatform.iOS:
        return 'ios-device';
      case TargetPlatform.linux:
        return 'linux-thinkpad-ui';
      default:
        return 'flutter-client';
    }
  }

  String get localDeviceName {
    if (kIsWeb) return 'Web Client';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Samsung Galaxy A34';
      case TargetPlatform.iOS:
        return 'iPhone';
      case TargetPlatform.linux:
        return 'Linux Desktop App';
      default:
        return 'Flutter Client';
    }
  }

  void start() {
    if (_running) return;
    _running = true;
    _startedAtMs = DateTime.now().millisecondsSinceEpoch;
    WidgetsBinding.instance.addObserver(this);

    // 1. Auto-register/heartbeat mobile device so Linux top bar sees both devices online
    _sendDeviceHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _sendDeviceHeartbeat();
    });

    // 2. Seed current local clipboard so we only auto-push NEW copies
    _seedInitialClipboard();

    // 3. Watch local clipboard every 400ms for near-instant seamless auto-copy sync
    _clipboardWatchTimer =
        Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (_autoSyncEnabled) {
        _checkLocalClipboardAndPush();
      }
    });

    // 4. Subscribe to remote clipboard events from Firebase RTDB
    if (ApiService().useFirebase && FirebaseService().isAuthenticated) {
      _devicesSub = FirebaseService().devicesStream().listen((devices) {
        _onlineDevices = devices.where((d) => d.isOnline).toList();
        notifyListeners();
      });

      _remoteClipSub = FirebaseService().clipboardStream().listen((evt) {
        if (evt == null) return;
        _handleIncomingRemoteClipboard(evt);
      });
    }

    // 5. Initialize Android Accessibility Service & Foreground Keep-Alive bridge
    BackgroundSyncService().init();
    BackgroundSyncService().onExternalClipboardReceived = (text) {
      if (_running && _autoSyncEnabled) {
        _handleDirectLocalClipboardPush(text);
      }
    };
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      BackgroundSyncService().startForegroundSync();
    }
  }

  void stop() {
    _running = false;
    WidgetsBinding.instance.removeObserver(this);
    _clipboardWatchTimer?.cancel();
    _heartbeatTimer?.cancel();
    _remoteClipSub?.cancel();
    _devicesSub?.cancel();
  }

  void setAutoSync(bool value) {
    _autoSyncEnabled = value;
    notifyListeners();
  }

  void markRead() {
    if (_hasUnreadClip || _unreadCount > 0) {
      _hasUnreadClip = false;
      _unreadCount = 0;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sendDeviceHeartbeat();
      if (_autoSyncEnabled) {
        // Multi-step focus burst on Android 10+ / Samsung One UI so clipboard is read
        // the exact moment window input focus is granted.
        for (final delayMs in const [80, 250, 550, 950]) {
          Future.delayed(Duration(milliseconds: delayMs), () {
            if (_running && _autoSyncEnabled) {
              _checkLocalClipboardAndPush();
            }
          });
        }
      }
    }
  }

  Future<void> _sendDeviceHeartbeat() async {
    if (!ApiService().useFirebase || !FirebaseService().isAuthenticated) return;
    // On Android, register/update 'android-sm-a346e' so Linux top bar shows both devices synced
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await FirebaseService().upsertClientDevicePresence(
          deviceId: localDeviceId,
          displayName: localDeviceName,
          platform: 'android',
        );
      } catch (_) {}
    }
  }

  Future<void> _seedInitialClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text != null && text.isNotEmpty) {
        _lastKnownClipboardText = text;
      }
    } catch (_) {}
  }

  Future<void> _handleDirectLocalClipboardPush(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || clean == _lastKnownClipboardText) return;
    _lastKnownClipboardText = clean;
    await pushClipboardNow(customText: clean, isAuto: true);
  }

  Future<void> _checkLocalClipboardAndPush() async {
    // On Linux Desktop, the Python background agent already watches xclip every 1s,
    // so only auto-watch from Flutter on Android/iOS/Web to avoid duplicate pushes.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) return;

    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text == null || text.isEmpty) return;
      if (text == _lastKnownClipboardText) return;

      _lastKnownClipboardText = text;
      await pushClipboardNow(customText: text, isAuto: true);
    } catch (_) {}
  }

  Future<bool> pushClipboardNow({String? customText, bool isAuto = false}) async {
    try {
      String? text = customText?.trim();
      if (text == null || text.isEmpty) {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        text = data?.text?.trim();
      }
      if (text == null || text.isEmpty) return false;

      _lastKnownClipboardText = text;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final evtId = 'evt_$nowMs';
      _lastEventKey = nowMs.toString();

      await ApiService().sendClipboardText(
        sourceDeviceId: localDeviceId,
        text: text,
        eventId: evtId,
      );

      final item = ClipboardSyncItem(
        text: text,
        sourceDeviceId: localDeviceName,
        timestamp: DateTime.now(),
        isIncoming: false,
      );
      _history.insert(0, item);
      if (_history.length > 20) _history.removeLast();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Clipboard push failed: $e');
      return false;
    }
  }

  Future<void> _handleIncomingRemoteClipboard(Map<String, dynamic> evt) async {
    final text = (evt['text'] as String?)?.trim();
    final src = (evt['sourceDeviceId'] as String?) ?? 'Remote Device';
    final createdAt = evt['createdAt']?.toString() ?? '';

    if (text == null || text.isEmpty) return;
    if (src == localDeviceId) return;
    if (createdAt.isNotEmpty && createdAt == _lastEventKey) return;

    // Ignore pre-existing snapshot older than session start on first attach
    final createdNum = evt['createdAt'];
    if (createdNum is num && _lastEventKey == null) {
      if (createdNum.toInt() < _startedAtMs - 1500) {
        _lastEventKey = createdAt;
        return;
      }
    }

    _lastEventKey = createdAt;
    if (text == _lastKnownClipboardText) return;
    _lastKnownClipboardText = text;

    await Clipboard.setData(ClipboardData(text: text));

    // Play subtle "dink" sound + haptic feedback
    try {
      await SystemSound.play(SystemSoundType.alert);
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.mediumImpact();
    } catch (_) {}

    final friendlySource = src.contains('linux')
        ? 'Linux ThinkPad'
        : src.contains('android')
            ? 'Samsung Phone'
            : src;

    final item = ClipboardSyncItem(
      text: text,
      sourceDeviceId: friendlySource,
      timestamp: DateTime.now(),
      isIncoming: true,
    );

    _history.insert(0, item);
    if (_history.length > 20) _history.removeLast();
    _hasUnreadClip = true;
    _unreadCount += 1;
    notifyListeners();

    onRemoteClipReceived?.call(item);
  }

  /// Displays a calm, minimal pastel floating pill toast at the bottom.
  static void showSamsungPillToast(
    BuildContext context, {
    required String title,
    required String preview,
    IconData icon = Icons.content_paste_go_rounded,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        backgroundColor:
            isDark ? const Color(0xF2262432) : const Color(0xF7FFFFFF),
        margin: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0xFF3B374D) : const Color(0xFFE4DFF2),
          ),
        ),
        duration: const Duration(milliseconds: 2400),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF332D4F) : const Color(0xFFECE8F8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 15,
                color:
                    isDark ? const Color(0xFFC4BBEA) : const Color(0xFF5D5094),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF282438),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (preview.isNotEmpty)
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFA8A3BC)
                            : const Color(0xFF6E6982),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
