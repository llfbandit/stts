package com.llfbandit.stts.stt

import com.llfbandit.stts.stt.permission.SttPermissionManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class SttMethodHandler(
  private val stt: Stt,
  private val permissionManager: SttPermissionManager
) : MethodCallHandler {
  override fun onMethodCall(call: MethodCall, result: Result) {
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
        stt.start()
        result.success(null)
      }

      "stop" -> {
        stt.stop()
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