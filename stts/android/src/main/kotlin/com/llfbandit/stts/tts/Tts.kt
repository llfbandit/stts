package com.llfbandit.stts.tts

import android.content.Context
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import android.util.Log
import com.llfbandit.stts.tts.model.TtsError
import com.llfbandit.stts.tts.model.TtsState
import com.llfbandit.stts.tts.stream.TtsStateStreamHandler
import java.util.UUID

data class UtteranceInfo(val id: String, val text: String)

class Tts(private val context: Context, private val ttsStateStreamHandler: TtsStateStreamHandler) {
  private val logTag = "Tts"

  private var tts: TextToSpeech? = null
  private var volume = 1.0f
  private var isSupported = false
  private val utterances = ArrayList<UtteranceInfo>()
  private var utteranceLastPosition = 0
  private var pauseRequested = false

  fun create(onResult: () -> Unit) {
    if (tts == null) {
      tts = TextToSpeech(context) { status -> onInit(status, onResult) }
    }
  }

  fun isSupported(): Boolean {
    if (!isSupported) {
      Log.e(logTag, "TTS is not supported.")
    }

    return isSupported
  }

  fun start(text: String) {
    if (!isSupported()) return

    val id = UUID.randomUUID().toString()
    utterances.add(UtteranceInfo(id, text))

    if (pauseRequested) {
      resume()
    } else {
      speak(text, id)
    }
  }

  fun pause() {
    if (!isSupported()) return

    pauseRequested = true
    tts?.stop()
    ttsStateStreamHandler.sendEvent(TtsState.Pause)
  }

  fun resume() {
    if (!isSupported()) return

    pauseRequested = false
    if (utterances.isEmpty()) return

    // Replay first utterance from last known position
    if (utteranceLastPosition != 0) {
      val info = utterances[0]
      utterances[0] = UtteranceInfo(
        info.id,
        info.text.substring(utteranceLastPosition.coerceIn(0, info.text.length - 1))
      )
    }

    utterances.forEach { (id, text) -> speak(text, id) }
  }

  fun stop() {
    if (!isSupported()) return

    tts?.stop()
    utterances.clear()
    utteranceLastPosition = 0
    pauseRequested = false

    ttsStateStreamHandler.sendEvent(TtsState.Stop)
  }

  fun setLanguage(lang: String) {
    if (!isSupported()) return

    val locale = tts!!.availableLanguages.firstOrNull {
      it.toLanguageTag() == lang
    }
    if (locale != null) {
      tts!!.language = locale
    }
  }

  fun getLanguage(): String {
    if (!isSupported()) return ""

    return tts!!.voice.locale.toLanguageTag()
  }

  fun getLanguages(): List<String> {
    if (!isSupported()) return emptyList()

    return tts!!.availableLanguages.map { it.toLanguageTag() }
  }

  fun setVoice(voiceId: String) {
    if (!isSupported()) return

    val voice = tts!!.voices.find { it.name == voiceId }

    if (voice != null) {
      tts!!.setVoice(voice)
    }
  }

  fun getVoices(): List<Map<String, Any>> {
    if (!isSupported()) return emptyList()

    return tts!!.voices.map { mapVoice(it) }
  }

  fun getVoicesByLanguage(language: String): List<Map<String, Any>> {
    if (!isSupported()) return emptyList()

    return tts!!.voices.filter {
      it.locale.toLanguageTag() == language
    }.map { mapVoice(it) }
  }

  fun setPitch(pitch: Float) {
    if (!isSupported()) return

    tts!!.setPitch(pitch.coerceIn(0.0f, 2.0f))
  }

  fun setRate(rate: Float) {
    if (!isSupported()) return

    tts!!.setSpeechRate(rate.coerceIn(0.1f, 10.0f))
  }

  fun setVolume(vol: Float) {
    volume = vol.coerceIn(0.0f, 1.0f)
  }

  fun dispose() {
    stop()

    tts?.shutdown()
    tts = null
  }

  private fun onInit(status: Int, onResult: () -> Unit = {}) {
    isSupported = status == TextToSpeech.SUCCESS

    if (!isSupported) {
      Log.e(logTag, "TTS Initialisation failed")
      ttsStateStreamHandler.sendErrorEvent(TtsError(-1, "initialisation"))
    } else {
      // (re-)create config in case of dispose.
      tts!!.setOnUtteranceProgressListener(utteranceProgressListener)
    }

    onResult()
  }

  private fun speak(text: String, utteranceId: String) {
    val params = Bundle()
    params.putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, volume)

    tts?.speak(text, TextToSpeech.QUEUE_ADD, params, utteranceId)
  }

  private val utteranceProgressListener = object : UtteranceProgressListener() {
    override fun onStart(utteranceId: String) {
      ttsStateStreamHandler.sendEvent(TtsState.Start)
    }

    override fun onDone(utteranceId: String) {
      val utterance = utterances.find { info -> info.id == utteranceId }
      utterances.remove(utterance)

      if (utterances.isEmpty()) {
        ttsStateStreamHandler.sendEvent(TtsState.Stop)
      }
    }

    @Deprecated("Deprecated in Java", ReplaceWith("onError(utteranceId: String, errorCode: Int)"))
    override fun onError(utteranceId: String) {
      onError(utteranceId, TextToSpeech.ERROR)
    }

    override fun onError(utteranceId: String, errorCode: Int) {
      val error = when (errorCode) {
        TextToSpeech.ERROR_NETWORK -> TtsError(errorCode, "network")
        TextToSpeech.ERROR_NETWORK_TIMEOUT -> TtsError(errorCode, "network_timeout")
        TextToSpeech.ERROR_OUTPUT -> TtsError(errorCode, "output")
        TextToSpeech.ERROR_SERVICE -> TtsError(errorCode, "service")
        TextToSpeech.ERROR_SYNTHESIS -> TtsError(errorCode, "synthesis")
        TextToSpeech.ERROR_INVALID_REQUEST -> TtsError(errorCode, "invalid_request")
        TextToSpeech.ERROR_NOT_INSTALLED_YET -> TtsError(errorCode, "not_installed_yet")
        else -> TtsError(errorCode, "unknown")
      }

      Log.e(logTag, "TTS error: $errorCode - ${error.message} error.")
      ttsStateStreamHandler.sendErrorEvent(error)
      stop()
    }

    // Keep track of current utterance and its progress
    // Called only on API 26+, otherwise resume will replay from index 0
    override fun onRangeStart(utteranceId: String, startAt: Int, endAt: Int, frame: Int) {
      utteranceLastPosition = startAt

      super.onRangeStart(utteranceId, startAt, endAt, frame)
    }
  }

  private fun mapVoice(voice: Voice): Map<String, Any> {
    return mapOf(
      "id" to voice.name,
      "language" to voice.locale.toLanguageTag(),
      "languageInstalled" to !voice.features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED),
      "name" to voice.name,
      "networkRequired" to voice.isNetworkConnectionRequired,
      "gender" to "unspecified"
    )
  }
}