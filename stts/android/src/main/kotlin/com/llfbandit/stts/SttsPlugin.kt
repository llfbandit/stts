package com.llfbandit.stts

import com.llfbandit.stts.permission.PermissionManager
import com.llfbandit.stts.stream.SpeechResultStreamHandler
import com.llfbandit.stts.stream.SpeechStateStreamHandler
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** SttsPlugin */
class SttsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
  companion object {
    const val EVENTS_STATE_CHANNEL = "com.llfbandit.stts/states"
    const val EVENTS_RESULT_CHANNEL = "com.llfbandit.stts/results"
  }

  private lateinit var channel: MethodChannel
  private var activityBinding: ActivityPluginBinding? = null

  private var permissionManager = PermissionManager()

  private lateinit var stts: Stts
  private var eventStateChannel: EventChannel? = null
  private val stateStreamHandler = SpeechStateStreamHandler()
  private var eventResultChannel: EventChannel? = null
  private val resultStreamHandler = SpeechResultStreamHandler()

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    val messenger = binding.binaryMessenger

    channel = MethodChannel(messenger, "stts")
    channel.setMethodCallHandler(this)

    eventStateChannel = EventChannel(messenger, EVENTS_STATE_CHANNEL)
    eventStateChannel?.setStreamHandler(stateStreamHandler)
    eventResultChannel = EventChannel(messenger, EVENTS_RESULT_CHANNEL)
    eventResultChannel?.setStreamHandler(resultStreamHandler)

    stts = Stts(binding.applicationContext, stateStreamHandler, resultStreamHandler)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    stts.dispose()

    eventStateChannel?.setStreamHandler(null)
    eventStateChannel = null

    eventResultChannel?.setStreamHandler(null)
    eventResultChannel = null
  }

  /////////////////////////////////////////////////////////////////////////////
  /// ActivityAware
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activityBinding = binding

    permissionManager.setActivity(binding.activity)
    activityBinding?.addRequestPermissionsResultListener(permissionManager)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onDetachedFromActivity()
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivity() {
    permissionManager.setActivity(null)
    activityBinding?.removeRequestPermissionsResultListener(permissionManager)

    activityBinding = null
  }
  /// END ActivityAware
  /////////////////////////////////////////////////////////////////////////////

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "isSupported" -> {
        result.success(stts.isSupported())
      }

      "hasPermission" -> {
        permissionManager.hasPermission(result::success)
      }

      "getLocale" -> {
        result.success(stts.getLocale())
      }

      "setLocale" -> {
        val language = call.argument<String>("language")
        if (language != null) {
          stts.setLocale(language)
        }
        result.success(null)
      }

      "getSupportedLocales" -> {
        stts.getSupportedLocales(result::success)
      }

      "start" -> {
        stts.start()
        result.success(null)
      }

      "stop" -> {
        stts.stop()
        result.success(null)
      }

      "dispose" -> {
        stts.dispose()
        result.success(null)
      }

      else -> {
        result.notImplemented()
      }
    }
  }
}
