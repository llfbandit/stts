package com.llfbandit.stts

import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.SpeechRecognizer
import com.llfbandit.stts.model.RecognitionError
import com.llfbandit.stts.model.State
import com.llfbandit.stts.stream.SpeechResultStreamHandler
import com.llfbandit.stts.stream.SpeechStateStreamHandler

class SpeechRecognitionListener(
  private val speechStateStreamHandler: SpeechStateStreamHandler,
  private val resultStreamHandler: SpeechResultStreamHandler
) : RecognitionListener {

  override fun onReadyForSpeech(params: Bundle?) = speechStateStreamHandler.sendEvent(State.Start)

  override fun onEndOfSpeech() = speechStateStreamHandler.sendEvent(State.Stop)

  override fun onResults(results: Bundle?) = doOnResults(results)

  override fun onPartialResults(partialResults: Bundle?) = doOnResults(partialResults)

  private fun doOnResults(results: Bundle?) {
    val data = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)

    if (!data.isNullOrEmpty()) {
      // the first element is the most likely candidate
      resultStreamHandler.sendEvent(data[0])
    }
  }

  override fun onError(error: Int) {
    // Use integers to get rid of API level checks
    val recognitionError = when (error) {
      SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> RecognitionError(1, "network_timeout")
      SpeechRecognizer.ERROR_NETWORK -> RecognitionError(2, "network")
      SpeechRecognizer.ERROR_AUDIO -> RecognitionError(3, "audio_error")
      SpeechRecognizer.ERROR_SERVER -> RecognitionError(4, "server")
      SpeechRecognizer.ERROR_CLIENT -> RecognitionError(5, "client")
      SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> RecognitionError(6, "speech_timeout")
      SpeechRecognizer.ERROR_NO_MATCH -> RecognitionError(7, "no_match")
      SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> RecognitionError(8, "recognizer_busy")
      SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> RecognitionError(9, "permission")
      SpeechRecognizer.ERROR_TOO_MANY_REQUESTS -> RecognitionError(10, "too_many_requests")
      SpeechRecognizer.ERROR_SERVER_DISCONNECTED -> RecognitionError(11, "server_disconnected")
      SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED -> RecognitionError(12, "language_not_supported")
      SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> RecognitionError(13, "language_unavailable")
      SpeechRecognizer.ERROR_CANNOT_CHECK_SUPPORT -> RecognitionError(14, "cannot_check_support")
      SpeechRecognizer.ERROR_CANNOT_LISTEN_TO_DOWNLOAD_EVENTS -> RecognitionError(15, "cannot_listen_to_download_events")
      else -> RecognitionError(error, "unknown")
    }

    if (recognitionError.code == SpeechRecognizer.ERROR_NO_MATCH) {
      // no_match is not processed as error, just trigger stop event
      // This error occurs when nothing has been detected, it may be a silence also.
      speechStateStreamHandler.sendEvent(State.Stop)
    } else {
      speechStateStreamHandler.sendErrorEvent(recognitionError)
    }
  }

  override fun onBeginningOfSpeech() {}
  override fun onRmsChanged(rmsdB: Float) {}
  override fun onBufferReceived(buffer: ByteArray?) {}
  override fun onEvent(eventType: Int, params: Bundle?) {}
}