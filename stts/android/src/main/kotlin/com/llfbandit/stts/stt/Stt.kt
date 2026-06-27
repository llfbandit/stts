package com.llfbandit.stts.stt

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.speech.ModelDownloadListener
import android.speech.RecognitionSupport
import android.speech.RecognitionSupportCallback
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import com.llfbandit.stts.stt.model.SttRecognitionOptions
import com.llfbandit.stts.stt.model.SttState
import com.llfbandit.stts.stt.stream.SttResultStreamHandler
import com.llfbandit.stts.stt.stream.SttStateStreamHandler
import java.util.Locale

class Stt(
  val context: Context,
  private val stateStreamHandler: SttStateStreamHandler,
  private val resultStreamHandler: SttResultStreamHandler
) {
  private val logTag = "Stt"
  private var currentLocale = Locale.getDefault()
  private var speechRecognizer: SpeechRecognizer? = null
  private var muteSystemSounds: Boolean = false
  private var originalRingerMode: Int = AudioManager.RINGER_MODE_NORMAL
  // Ringer mode has been switched to vibrate by us and must be restored.
  private var ringerMuted = false
  private var pendingRingerRestore: Runnable? = null
  private val uiThreadHandler = Handler(Looper.getMainLooper())
  private val audioManager by lazy { context.getSystemService(Context.AUDIO_SERVICE) as AudioManager }

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

    SpeechLanguageHelper().getSupportedLocales(context) {
      // Fall back to device language when languages could not be retrieved.
      resultCallback.onResult(it.ifEmpty { listOf(Locale.getDefault().toLanguageTag()) })
    }
  }

  fun start(options: SttRecognitionOptions) {
    if (!isSupported()) return

    // Previous session is still restoring ringer mode. Complete its stop now.
    if (cancelRingerRestore()) {
      // Keep the ringer muted for this session, unless muting has been disabled meanwhile.
      if (!muteSystemSounds) unmuteRinger()
      stateStreamHandler.sendEvent(SttState.Stop)
    }

    if (speechRecognizer == null) {
      createSpeechRecognizer()
      saveRingerMode()
    }

    val recognizerIntent = setupRecognitionIntent(options)

    setRingerModeVibrate()

    speechRecognizer?.startListening(recognizerIntent)
  }

  // restoreNow: restores ringer mode without delay, when no quick restart can follow.
  fun stop(restoreNow: Boolean = false) {
    if (!isSupported()) return

    speechRecognizer?.setRecognitionListener(null)
    speechRecognizer?.cancel()
    speechRecognizer?.destroy()
    speechRecognizer = null

    restoreRingerMode(restoreNow, onRestored = { stateStreamHandler.sendEvent(SttState.Stop) })
  }

  // onEnd is called on the main thread.
  fun downloadModel(language: String, onEnd: (errCode: Int?) -> Unit) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
      Log.d(
        logTag,
        "Device API too low: ${Build.VERSION.SDK_INT} vs. ${Build.VERSION_CODES.UPSIDE_DOWN_CAKE}."
      )
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
      intent, context.mainExecutor, object :
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
            context.mainExecutor,
            object : ModelDownloadListener {
              override fun onProgress(progress: Int) {}
              override fun onScheduled() {
                Log.d(
                  logTag,
                  "Model download has been scheduled... We won't receive any other event."
                )
                onEnd(null)
                recognizer.destroy()
              }

              override fun onSuccess() {
                onEnd(null)
                recognizer.destroy()
              }

              override fun onError(error: Int) {
                Log.e(
                  logTag,
                  "Error when downloading model. SpeechRecognizer.RecognitionError code: $error"
                )
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

  fun muteSystemSounds(mute: Boolean) {
    muteSystemSounds = mute
  }

  fun dispose() {
    // The plugin may be detached right after.
    stop(restoreNow = true)

    muteSystemSounds = false
  }

  private fun createSpeechRecognizer() {
    if (speechRecognizer == null) {
      speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)

      speechRecognizer?.setRecognitionListener(
        SttRecognitionListener(
          stateStreamHandler,
          resultStreamHandler,
          onStop = { stop() })
      )
    }
  }

  private fun setupRecognitionIntent(options: SttRecognitionOptions): Intent {
    val recognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
      putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, options.model)
      putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)

      if (currentLocale != Locale.getDefault()) {
        putExtra(RecognizerIntent.EXTRA_LANGUAGE, currentLocale.toLanguageTag())
      }

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && options.offline) {
        // Only set this when required to deal with older APIs (error 12, 13)
        putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
      }

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        if (options.punctuation) {
          putExtra(
            RecognizerIntent.EXTRA_ENABLE_FORMATTING,
            RecognizerIntent.FORMATTING_OPTIMIZE_QUALITY
          )
        }

        if (options.contextualStrings.isNotEmpty()) {
          putExtra(RecognizerIntent.EXTRA_BIASING_STRINGS, options.contextualStrings)
        }
      }
    }

    return recognizerIntent
  }

  private fun saveRingerMode() {
    // Current mode is still muted by us. Keep the saved one.
    if (ringerMuted) return

    originalRingerMode = audioManager.ringerMode
  }

  private fun setRingerModeVibrate() {
    if (muteSystemSounds && originalRingerMode == AudioManager.RINGER_MODE_NORMAL) {
      audioManager.ringerMode = AudioManager.RINGER_MODE_VIBRATE
      ringerMuted = true
    }
  }

  private fun restoreRingerMode(now: Boolean, onRestored: () -> Unit) {
    if (!ringerMuted) {
      onRestored()
      return
    }

    cancelRingerRestore()

    if (now) {
      unmuteRinger()
      onRestored()
      return
    }

    val restore = Runnable {
      pendingRingerRestore = null
      unmuteRinger()
      onRestored()
    }
    pendingRingerRestore = restore
    uiThreadHandler.postDelayed(restore, 400)
  }

  private fun unmuteRinger() {
    audioManager.ringerMode = originalRingerMode
    ringerMuted = false
  }

  private fun cancelRingerRestore(): Boolean {
    val restore = pendingRingerRestore ?: return false

    uiThreadHandler.removeCallbacks(restore)
    pendingRingerRestore = null
    return true
  }
}
