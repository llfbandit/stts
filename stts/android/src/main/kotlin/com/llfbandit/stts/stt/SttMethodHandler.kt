package com.llfbandit.stts.stt

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.llfbandit.stts.stt.model.SttRecognitionOptions
import com.llfbandit.stts.stt.permission.SttPermissionManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class SttMethodHandler(
  private val stt: Stt,
  private val permissionManager: SttPermissionManager,
  private val methodChannel: MethodChannel
) : MethodCallHandler {
  private val logTag = "Stt"

  private var isInitialized = false
  private val pendingCalls = ArrayList<Runnable>()
  private var hasLanguages = false

  override fun onMethodCall(call: MethodCall, result: Result) {
    // SpeechToText may fail with offline mode.
    // Retrieve languages to check if it's safe to use and stack all calls during this period.
    if (!isInitialized && call.method != "dispose") {
      pendingCalls.add(Runnable { onSafeCall(call, result) })

      if (stt.isSupported()) {
        SpeechLanguageHelper().getSupportedLocales(stt.context) {
          hasLanguages = it != null

          if (!hasLanguages) {
            Log.d(logTag, "Speech recognition: Unable to retrieve languages. Offline mode disabled.")
          }

          onInitialized()
        }
      } else {
        onInitialized()
      }
    } else {
      onSafeCall(call, result)
    }
  }

  private fun onInitialized() {
    isInitialized = true

    for (pendingCall in pendingCalls) {
      pendingCall.run()
    }
    pendingCalls.clear()
  }

  private fun onSafeCall(call: MethodCall, result: Result) {
    when (call.method) {
      "isSupported" -> {
        result.success(stt.isSupported())
      }

      "hasPermission" -> {
        permissionManager.hasPermission(result::success)
      }

      "getLanguage" -> {
        result.success(stt.getLanguage())
      }

      "setLanguage" -> {
        val language = call.argument<String>("language")
        if (language != null) {
          stt.setLanguage(language)
        }
        result.success(null)
      }

      "getLanguages" -> {
        stt.getLanguages(result::success)
      }

      "start" -> {
        val options = call.argument<Map<String, Any>>("options")
        if (options != null) {
          stt.start(SttRecognitionOptions.fromMap(options, hasLanguages))
        }
        result.success(null)
      }

      "stop" -> {
        stt.stop()
        result.success(null)
      }

      "android.downloadModel" -> {
        val language = call.argument<String>("language")
        if (language != null) {
          stt.downloadModel(
            language,
            onEnd = {
              Handler(Looper.getMainLooper()).post {
                methodChannel.invokeMethod("android.onDownloadModelEnd", mapOf("language" to language, "error" to it))
              }
            },
          )
        }
        result.success(null)
      }

      "android.muteSystemSounds" -> {
        val mute = call.argument<Boolean>("mute")
        if (mute!=null) {
          stt.muteSystemSounds(mute)
        }
        result.success(null)
      }

      "dispose" -> {
        stt.dispose()
        result.success(null)
      }

      else -> {
        result.notImplemented()
      }
    }
  }
}