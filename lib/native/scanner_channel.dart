import 'package:flutter/services.dart';

/// The `MethodChannel("scanner")` bridge to `MainActivity.kt`.
/// See android_native/README.md and android/app/.../MainActivity.kt.
class ScannerChannel {
  ScannerChannel._();
  static const MethodChannel _channel = MethodChannel('scanner');

  /// Fires when the bubble/tile opens the scanner or (long-press) history.
  /// [onOpenScanner] / [onOpenHistory] run whenever the method channel
  /// receives the matching call, including while the app is already open.
  static void listen({VoidCallback? onOpenScanner, VoidCallback? onOpenHistory}) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'openScanner':
          onOpenScanner?.call();
        case 'openHistory':
          onOpenHistory?.call();
      }
    });
  }

  static Future<bool> canDrawOverlays() async =>
      (await _channel.invokeMethod<bool>('canDrawOverlays')) ?? false;

  static Future<void> requestOverlayPermission() =>
      _channel.invokeMethod('requestOverlayPermission');

  static Future<bool> isIgnoringBatteryOptimizations() async =>
      (await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations')) ?? false;

  static Future<void> requestIgnoreBatteryOptimizations() =>
      _channel.invokeMethod('requestIgnoreBatteryOptimizations');

  static Future<void> openAutostartSettings() =>
      _channel.invokeMethod('openAutostartSettings');

  static Future<void> startBubble() => _channel.invokeMethod('startBubble');

  static Future<void> stopBubble() => _channel.invokeMethod('stopBubble');
}
