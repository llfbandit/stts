package com.llfbandit.stts

import com.llfbandit.stts.stt.Stt
import com.llfbandit.stts.stt.SttMethodHandler
import com.llfbandit.stts.stt.permission.SttPermissionManager
import com.llfbandit.stts.stt.stream.SttResultStreamHandler
import com.llfbandit.stts.stt.stream.SttStateStreamHandler
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/** SttsPlugin */
class SttsPlugin : FlutterPlugin, ActivityAware {
  companion object {
    const val STT_METHODS_CHANNEL = "com.llfbandit.stt/methods"
    const val STT_EVENTS_STATE_CHANNEL = "com.llfbandit.stt/states"
    const val STT_EVENTS_RESULT_CHANNEL = "com.llfbandit.stt/results"
  }

  private var activityBinding: ActivityPluginBinding? = null

  // STT members
  private lateinit var stt: Stt
  private var sttPermissionManager = SttPermissionManager()
  private lateinit var sttMethodChannel: MethodChannel
  private var sttEventStateChannel: EventChannel? = null
  private val sttStateStreamHandler = SttStateStreamHandler()
  private var sttEventResultChannel: EventChannel? = null
  private val sttResultStreamHandler = SttResultStreamHandler()

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    val messenger = binding.binaryMessenger

    sttEventStateChannel = EventChannel(messenger, STT_EVENTS_STATE_CHANNEL)
    sttEventStateChannel?.setStreamHandler(sttStateStreamHandler)
    sttEventResultChannel = EventChannel(messenger, STT_EVENTS_RESULT_CHANNEL)
    sttEventResultChannel?.setStreamHandler(sttResultStreamHandler)

    stt = Stt(binding.applicationContext, sttStateStreamHandler, sttResultStreamHandler)

    sttMethodChannel = MethodChannel(messenger, STT_METHODS_CHANNEL)
    sttMethodChannel.setMethodCallHandler(SttMethodHandler(stt, sttPermissionManager))
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    sttMethodChannel.setMethodCallHandler(null)
    stt.dispose()

    sttEventStateChannel?.setStreamHandler(null)
    sttEventStateChannel = null

    sttEventResultChannel?.setStreamHandler(null)
    sttEventResultChannel = null
  }

  /////////////////////////////////////////////////////////////////////////////
  /// ActivityAware
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activityBinding = binding

    sttPermissionManager.setActivity(binding.activity)
    activityBinding?.addRequestPermissionsResultListener(sttPermissionManager)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onDetachedFromActivity()
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivity() {
    sttPermissionManager.setActivity(null)
    activityBinding?.removeRequestPermissionsResultListener(sttPermissionManager)

    activityBinding = null
  }
  /// END ActivityAware
  /////////////////////////////////////////////////////////////////////////////

}
