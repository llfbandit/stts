package com.llfbandit.stts.stt

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
  private var hasLanguages = false

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (isInitialized || call.method == "dispose" || !stt.isSupported()) {
      onSafeCall(call, result)
      return
    }

    // SpeechToText may fail with offline mode.
    // Retrieve languages first to check if it's safe to use.
    // Dart side runs calls one at a time, no other call is received meanwhile.
    SpeechLanguageHelper().getSupportedLocales(stt.context) {
      hasLanguages = it.isNotEmpty()
      isInitialized = true

      if (!hasLanguages) {
        Log.d(logTag, "Speech recognition: Unable to retrieve languages. Offline mode disabled.")
      }

      onSafeCall(call, result, it)
    }
  }

  // languages: already retrieved languages, if any.
  private fun onSafeCall(call: MethodCall, result: Result, languages: List<String>? = null) {
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
        if (languages != null) {
          result.success(stt.withDefaultLanguage(languages))
        } else {
          stt.getLanguages(result::success)
        }
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
        // An early error is returned, the dart side reports it once the call returned.
        val errCode = language?.let {
          stt.downloadModel(
            language,
            onEnd = {
              methodChannel.invokeMethod("android.onDownloadModelEnd", mapOf("language" to language, "error" to it))
            },
          )
        }
        result.success(errCode)
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