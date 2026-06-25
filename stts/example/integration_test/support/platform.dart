import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

bool get isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Skips the current test and returns false.
///
/// Also prints the [reason], `flutter test` doesn't report it.
bool skipTest(String reason) {
  debugPrint('Skipped: $reason');
  markTestSkipped(reason);
  return false;
}

/// Native helpers of the example app, used to check platform state from tests.
///
/// Android only. See MainActivity.kt.
class TestHooks {
  static const _channel = MethodChannel('stts_example/test_hooks');

  // AudioManager.RINGER_MODE_* values.
  static const ringerModeVibrate = 1;
  static const ringerModeNormal = 2;

  static Future<int> getSdkInt() async {
    return (await _channel.invokeMethod<int>('getSdkInt'))!;
  }

  static Future<int> getRingerMode() async {
    return (await _channel.invokeMethod<int>('getRingerMode'))!;
  }

  static Future<bool> hasVibrator() async {
    return (await _channel.invokeMethod<bool>('hasVibrator'))!;
  }

  static Future<bool> isMusicActive() async {
    return (await _channel.invokeMethod<bool>('isMusicActive'))!;
  }

  static Future<void> setRingerMode(int mode) {
    return _channel.invokeMethod('setRingerMode', {'mode': mode});
  }
}
