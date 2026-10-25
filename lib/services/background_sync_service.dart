import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform bridge for Android Accessibility Service, Battery Optimization,
/// and Foreground Service keep-alive controls.
class BackgroundSyncService {
  static final BackgroundSyncService _instance =
      BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  static const MethodChannel _channel =
      MethodChannel('com.example.world_of_iot/background_sync');

  bool _initialized = false;
  void Function(String text)? onExternalClipboardReceived;

  void init() {
    if (_initialized) return;
    _initialized = true;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onClipboardChanged') {
          final args = call.arguments as Map?;
          final text = args?['text'] as String?;
          if (text != null && text.isNotEmpty) {
            onExternalClipboardReceived?.call(text);
          }
        }
      });
    }
  }

  Future<bool> isAccessibilityEnabled() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final res = await _channel.invokeMethod<bool>('isAccessibilityEnabled');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  Future<bool> isBatteryOptimizationIgnored() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final res =
          await _channel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return res ?? false;
    } catch (_) {
      return true;
    }
  }

  Future<void> requestIgnoreBatteryOptimization() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimization');
    } catch (_) {}
  }

  Future<void> startForegroundSync() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('startForegroundSync');
    } catch (_) {}
  }

  Future<void> stopForegroundSync() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('stopForegroundSync');
    } catch (_) {}
  }

  Future<bool> isForegroundServiceRunning() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final res =
          await _channel.invokeMethod<bool>('isForegroundServiceRunning');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
