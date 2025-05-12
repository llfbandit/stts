package com.llfbandit.stts.stt

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.speech.RecognitionSupport
import android.speech.RecognitionSupportCallback
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer.createOnDeviceSpeechRecognizer
import java.util.concurrent.Executors

fun interface SupportedLanguagesResultCallback {
  fun onResult(locales: List<String>)
}

class SpeechLanguageHelper {
  fun getSupportedLocales(context: Context, resultCallback: SupportedLanguagesResultCallback) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      val recognizer = createOnDeviceSpeechRecognizer(context)
      val recognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)

      recognizer.checkRecognitionSupport(
        recognizerIntent, Executors.newSingleThreadExecutor(), object : RecognitionSupportCallback {
          override fun onSupportResult(recognitionSupport: RecognitionSupport) {
            val result = HashSet<String>()
            result.addAll(recognitionSupport.installedOnDeviceLanguages)
            result.addAll(recognitionSupport.onlineLanguages)
            result.addAll(recognitionSupport.supportedOnDeviceLanguages)

            recognizer.destroy()
            resultCallback.onResult(result.toList())
          }

          override fun onError(error: Int) {
            recognizer.destroy()
            resultCallback.onResult(ArrayList())
          }
        })
    } else {
      val intent = Intent(RecognizerIntent.ACTION_GET_LANGUAGE_DETAILS)

      context.sendOrderedBroadcast(intent, null, object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
          if (resultCode == Activity.RESULT_OK) {
            val results = getResultExtras(true)

            resultCallback.onResult(
              results.getStringArrayList(RecognizerIntent.EXTRA_SUPPORTED_LANGUAGES) ?: ArrayList()
            )
          } else {
            resultCallback.onResult(ArrayList())
          }
        }
      }, null, Activity.RESULT_OK, null, null)
    }
  }
}