package com.llfbandit.stts.tts.stream

import android.os.Handler
import android.os.Looper
import com.llfbandit.stts.tts.model.TtsError
import com.llfbandit.stts.tts.model.TtsState
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink

class TtsStateStreamHandler : EventChannel.StreamHandler {
  // Event producer
  private var eventSink: EventSink? = null
  private var state: TtsState = TtsState.Stop

  private val uiThreadHandler = Handler(Looper.getMainLooper())

  override fun onListen(arguments: Any?, events: EventSink?) {
    this.eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  fun sendEvent(state: TtsState) {
    if (this.state != state) {
      this.state = state

      uiThreadHandler.post {
        eventSink?.success(state.ordinal)
      }
    }
  }

  fun sendErrorEvent(error: TtsError) {
    uiThreadHandler.post {
      eventSink?.error("${error.code}", error.message, null)
    }
  }
}