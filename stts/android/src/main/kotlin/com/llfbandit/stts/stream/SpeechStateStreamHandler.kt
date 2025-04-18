package com.llfbandit.stts.stream

import android.os.Handler
import android.os.Looper
import com.llfbandit.stts.model.RecognitionError
import com.llfbandit.stts.model.State
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink

class SpeechStateStreamHandler : EventChannel.StreamHandler {
  // Event producer
  private var eventSink: EventSink? = null

  private val uiThreadHandler = Handler(Looper.getMainLooper())

  override fun onListen(arguments: Any?, events: EventSink?) {
    this.eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  fun sendEvent(state: State) {
    uiThreadHandler.post {
      eventSink?.success(state.ordinal)
    }
  }

  fun sendErrorEvent(error: RecognitionError) {
    uiThreadHandler.post {
      eventSink?.error("${error.code}", error.message, null)
    }
  }
}