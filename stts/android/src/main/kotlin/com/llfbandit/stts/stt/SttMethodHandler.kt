package com.llfbandit.stts.stt

import android.os.Handler
import android.os.Looper
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
  override fun onMethodCall(call: MethodCall, result: Result) = when (call.method) {
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
      stt.start()
      result.success(null)
    }

    "stop" -> {
      stt.stop()
      result.success(null)
    }

    "downloadModel" -> {
      val language = call.argument<String>("language")
      if (language != null) {
        stt.downloadModel(
          language,
          onEnd = {
            Handler(Looper.getMainLooper()).post {
              methodChannel.invokeMethod("onDownloadModelEnd", mapOf("language" to language, "error" to it))
            }
          },
        )
      }
      result.success(null)
    }

    "muteSystemSounds" -> {
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