package com.llfbandit.stts.stt.stream

import android.os.Handler
import android.os.Looper
import com.llfbandit.stts.stt.model.SttRecognitionError
import com.llfbandit.stts.stt.model.SttState
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink

class SttStateStreamHandler : EventChannel.StreamHandler {
  // Event producer
  private var eventSink: EventSink? = null
  private var state: SttState = SttState.Stop

  private val uiThreadHandler = Handler(Looper.getMainLooper())

  override fun onListen(arguments: Any?, events: EventSink?) {
    this.eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  fun sendEvent(state: SttState) {
    if (this.state != state) {
      this.state = state

      uiThreadHandler.post {
        eventSink?.success(state.ordinal)
      }
    }
  }

  fun sendErrorEvent(error: SttRecognitionError) {
    uiThreadHandler.post {
      eventSink?.error("${error.code}", error.message, null)
    }
  }
}