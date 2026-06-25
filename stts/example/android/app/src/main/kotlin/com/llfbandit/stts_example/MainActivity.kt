package com.llfbandit.stts_example

import android.media.AudioManager
import android.os.Build
import android.os.Vibrator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    // Helpers for integration tests to check platform state (see integration_test/).
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "stts_example/test_hooks")
      .setMethodCallHandler { call, result ->
        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager

        when (call.method) {
          "getSdkInt" -> result.success(Build.VERSION.SDK_INT)
          "getRingerMode" -> result.success(audioManager.ringerMode)
          // TTS plays on the music stream by default.
          "isMusicActive" -> result.success(audioManager.isMusicActive)
          "hasVibrator" -> {
            @Suppress("DEPRECATION")
            val vibrator = getSystemService(VIBRATOR_SERVICE) as Vibrator?
            result.success(vibrator?.hasVibrator() == true)
          }
          "setRingerMode" -> {
            try {
              audioManager.ringerMode = call.argument<Int>("mode")!!
              result.success(null)
            } catch (e: SecurityException) {
              result.error("setRingerMode", e.message, null)
            }
          }

          else -> result.notImplemented()
        }
      }
  }
}
