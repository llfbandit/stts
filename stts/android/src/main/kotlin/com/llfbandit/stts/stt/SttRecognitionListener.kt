package com.llfbandit.stts.stt

import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.SpeechRecognizer
import com.llfbandit.stts.stt.model.SttRecognitionError
import com.llfbandit.stts.stt.model.SttState
import com.llfbandit.stts.stt.stream.SttResultStreamHandler
import com.llfbandit.stts.stt.stream.SttStateStreamHandler

class SttRecognitionListener(
  private val stateStreamHandler: SttStateStreamHandler,
  private val resultStreamHandler: SttResultStreamHandler,
  private val onStop: () -> Unit,
): RecognitionListener {
  override fun onReadyForSpeech(params: Bundle?) = stateStreamHandler.sendEvent(SttState.Start)

  override fun onEndOfSpeech() = onStop()

  override fun onResults(results: Bundle?) = doOnResults(results)

  override fun onPartialResults(partialResults: Bundle?) = doOnResults(partialResults)

  private fun doOnResults(results: Bundle?) {
    val data = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)

    if (!data.isNullOrEmpty()) {
      // The first element is the most likely candidate
      resultStreamHandler.sendEvent(data[0])
    }
  }

  override fun onError(error: Int) {
    // Use integers to get rid of API level checks
    val recognitionError = when (error) {
      SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> SttRecognitionError(1, "network_timeout")
      SpeechRecognizer.ERROR_NETWORK -> SttRecognitionError(2, "network")
      SpeechRecognizer.ERROR_AUDIO -> SttRecognitionError(3, "audio_error")
      SpeechRecognizer.ERROR_SERVER -> SttRecognitionError(4, "server")
      SpeechRecognizer.ERROR_CLIENT -> SttRecognitionError(5, "client")
      SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> SttRecognitionError(6, "speech_timeout")
      SpeechRecognizer.ERROR_NO_MATCH -> SttRecognitionError(7, "no_match")
      SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> SttRecognitionError(8, "recognizer_busy")
      SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> SttRecognitionError(9, "permission")
      SpeechRecognizer.ERROR_TOO_MANY_REQUESTS -> SttRecognitionError(10, "too_many_requests")
      SpeechRecognizer.ERROR_SERVER_DISCONNECTED -> SttRecognitionError(11, "server_disconnected")
      SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED -> SttRecognitionError(12, "language_not_supported")
      SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> SttRecognitionError(13, "language_unavailable")
      SpeechRecognizer.ERROR_CANNOT_CHECK_SUPPORT -> SttRecognitionError(14, "cannot_check_support")
      SpeechRecognizer.ERROR_CANNOT_LISTEN_TO_DOWNLOAD_EVENTS -> SttRecognitionError(15, "cannot_listen_to_download_events")
      else -> SttRecognitionError(error, "unknown")
    }

    if (recognitionError.code == SpeechRecognizer.ERROR_NO_MATCH) {
      // no_match is not processed as error, just trigger stop event
      // This error occurs when nothing has been detected, it may be a silence also.
      onStop()
    } else {
      stateStreamHandler.sendErrorEvent(recognitionError)
      onStop()
    }
  }

  override fun onBeginningOfSpeech() {}
  override fun onRmsChanged(rmsdB: Float) {}
  override fun onBufferReceived(buffer: ByteArray?) {}
  override fun onEvent(eventType: Int, params: Bundle?) {}
}