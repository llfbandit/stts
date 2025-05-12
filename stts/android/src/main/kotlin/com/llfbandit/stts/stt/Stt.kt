package com.llfbandit.stts.stt

import android.content.Context
import android.content.Intent
import android.os.Build
import android.speech.ModelDownloadListener
import android.speech.RecognitionSupport
import android.speech.RecognitionSupportCallback
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import com.llfbandit.stts.stt.model.SttState
import com.llfbandit.stts.stt.stream.SttResultStreamHandler
import com.llfbandit.stts.stt.stream.SttStateStreamHandler
import java.util.Locale
import java.util.concurrent.Executors

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

  fun getLanguage(): String = currentLocale.toLanguageTag()

  fun setLanguage(language: String) {
    currentLocale = Locale.forLanguageTag(language)
  }

  fun getLanguages(resultCallback: SupportedLanguagesResultCallback) {
    if (!isSupported()) {
      resultCallback.onResult(ArrayList())
      return
    }

    return SpeechLanguageHelper().getSupportedLocales(context, resultCallback)
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

  fun downloadModel(language: String, onEnd: (errCode: Int?) -> Unit) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
      Log.d(logTag, "Device API too low: ${Build.VERSION.SDK_INT} vs. ${Build.VERSION_CODES.UPSIDE_DOWN_CAKE}.")
      return
    }

    val result = SpeechRecognizer.isOnDeviceRecognitionAvailable(context)
    if (!result) {
      Log.d(logTag, "On device speech recognition is not supported.")
      return
    }

    val recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(context)

    val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)

    // Check if language is already installed before triggering UI.
    recognizer.checkRecognitionSupport(
      intent, Executors.newSingleThreadExecutor(), object :
        RecognitionSupportCallback {
        override fun onSupportResult(recognitionSupport: RecognitionSupport) {
          if (recognitionSupport.installedOnDeviceLanguages.contains(language)) {
            onEnd(null)
            recognizer.destroy()
            return
          }

          intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)

          recognizer.triggerModelDownload(
            intent,
            Executors.newSingleThreadExecutor(),
            object : ModelDownloadListener {
              override fun onProgress(progress: Int) {}
              override fun onScheduled() {
                Log.d(logTag, "Model download has been scheduled... We won't receive any other event.")
                onEnd(null)
                recognizer.destroy()
              }

              override fun onSuccess() {
                onEnd(null)
                recognizer.destroy()
              }

              override fun onError(error: Int) {
                Log.e(logTag, "Error when downloading model. SpeechRecognizer.RecognitionError code: $error")
                onEnd(error)
                recognizer.destroy()
              }
            },
          )
        }

        override fun onError(error: Int) {
          onEnd(error)
          recognizer.destroy()
        }
      }
    )
  }

  fun dispose() {
    stop()

    speechRecognizer?.setRecognitionListener(null)
    speechRecognizer?.destroy()
    speechRecognizer = null
  }
}
