package com.llfbandit.stts.stream

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink

class SpeechResultStreamHandler: EventChannel.StreamHandler {
  // Event producer
  private var eventSink: EventSink? = null

  private val uiThreadHandler = Handler(Looper.getMainLooper())

  override fun onListen(arguments: Any?, events: EventSink?) {
    this.eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  fun sendEvent(result: String) {
    uiThreadHandler.post {
      eventSink?.success(result)
    }
  }
}