package com.llfbandit.stts.stt

import android.content.Context
import android.content.Intent
import android.os.Build
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import com.llfbandit.stts.stt.model.SttState
import com.llfbandit.stts.stt.stream.SttResultStreamHandler
import com.llfbandit.stts.stt.stream.SttStateStreamHandler
import java.util.Locale

class Stt(
  private val context: Context,
  private val stateStreamHandler: SttStateStreamHandler,
  private val resultStreamHandler: SttResultStreamHandler
) {
  private val logTag = "Stt"
  private var currentLocale = Locale.getDefault()
  private var speechRecognizer: SpeechRecognizer? = null

  fun isSupported(): Boolean {
    val result = SpeechRecognizer.isRecognitionAvailable(context)

    if (!result) {
      Log.d(logTag, "Speech recognition is not supported.")
    }

    return result
  }

  fun getLocale(): String = currentLocale.toLanguageTag()

  fun setLocale(language: String) {
    currentLocale = Locale.forLanguageTag(language)
  }

  fun getSupportedLocales(resultCallback: SupportedLocalesResultCallback) {
    if (!isSupported()) {
      resultCallback.onResult(ArrayList())
      return
    }

    return SpeechLocaleHelper().getSupportedLocales(context, resultCallback)
  }

  fun start() {
    if (!isSupported()) return

    if (speechRecognizer == null) {
      speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
    }

    speechRecognizer?.setRecognitionListener(
      SttRecognitionListener(stateStreamHandler, resultStreamHandler, onStop = { stop() })
    )

    val recognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
      putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
      putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
      putExtra(RecognizerIntent.EXTRA_LANGUAGE, currentLocale.toLanguageTag())
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
      }
    }

    speechRecognizer?.startListening(recognizerIntent)
  }

  fun stop() {
    if (!isSupported()) return

    speechRecognizer?.setRecognitionListener(null)
    speechRecognizer?.cancel()
    stateStreamHandler.sendEvent(SttState.Stop)
  }

  fun dispose() {
    stop()

    speechRecognizer?.setRecognitionListener(null)
    speechRecognizer?.destroy()
    speechRecognizer = null
  }
}
