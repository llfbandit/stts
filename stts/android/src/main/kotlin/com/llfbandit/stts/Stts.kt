package com.llfbandit.stts

import android.content.Context
import android.content.Intent
import android.os.Build
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import com.llfbandit.stts.model.State
import com.llfbandit.stts.stream.SpeechResultStreamHandler
import com.llfbandit.stts.stream.SpeechStateStreamHandler
import java.util.Locale

class Stts(
  private val context: Context,
  private val speechStateStreamHandler: SpeechStateStreamHandler,
  private val resultStreamHandler: SpeechResultStreamHandler
) {
  private val logTag = "Stts"
  private var currentLocale = Locale.getDefault()
  private var speechRecognizer: SpeechRecognizer? = null

  fun isSupported(): Boolean {
    val result = SpeechRecognizer.isRecognitionAvailable(context)

    if (!result) {
      Log.d(logTag, "SpeechRecognizer is not supported.")
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

    recognizer.setRecognitionListener(
      SpeechRecognitionListener(speechStateStreamHandler, resultStreamHandler)
    )

    val recognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
      putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
      putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
      putExtra(RecognizerIntent.EXTRA_LANGUAGE, currentLocale.toLanguageTag())
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
      }
    }

    recognizer.startListening(recognizerIntent)
  }

  fun stop() {
    if (!isSupported()) return

    recognizer.cancel()
    dispose()
    speechStateStreamHandler.sendEvent(State.Stop)
  }

  fun dispose() {
    speechRecognizer?.stopListening()
    speechRecognizer?.setRecognitionListener(null)

    speechRecognizer?.destroy()
    speechRecognizer = null
  }

  private val recognizer: SpeechRecognizer
    get() {
      if (speechRecognizer == null) {
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
      }

      return speechRecognizer!!
    }
}