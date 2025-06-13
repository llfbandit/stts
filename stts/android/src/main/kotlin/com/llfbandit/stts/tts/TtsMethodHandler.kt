package com.llfbandit.stts.tts

import com.llfbandit.stts.tts.model.TtsOptions
import com.llfbandit.stts.tts.model.TtsQueueMode
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class TtsMethodHandler(private val tts: Tts) : MethodCallHandler {
  private var isInitialized = false
  private val pendingCalls = ArrayList<Runnable>()

  override fun onMethodCall(call: MethodCall, result: Result) {
    // TextToSpeech is fully initialized from a listener.
    // Let's stack all calls during this period.
    // This avoids messy code in Tts class to deal with this and also ease dispose/creation multiple times.
    // This code is safe because there's a semaphore on dart side to ensure only one call is made at a time.
    if (!isInitialized && call.method != "dispose") {
      pendingCalls.add(Runnable { onSafeCall(call, result) })

      tts.create {
        isInitialized = true

        for (pendingCall in pendingCalls) {
          pendingCall.run()
        }
        pendingCalls.clear()
      }
    } else {
      onSafeCall(call, result)
    }
  }

  private fun onSafeCall(call: MethodCall, result: Result) {
    when (call.method) {
      "isSupported" -> {
        result.success(tts.isSupported())
      }

      "start" -> {
        val text = call.argument<String>("text")!!
        val queueMode = call.argument<String>("mode")!!
        val options = TtsOptions(
          TtsQueueMode.valueOf(queueMode.replaceFirstChar { it.uppercaseChar() }),
          call.argument<Int>("preSilence"),
          call.argument<Int>("postSilence")
        )

        tts.start(text, options)
        result.success(null)
      }

      "pause" -> {
        tts.pause()
        result.success(null)
      }

      "resume" -> {
        tts.resume()
        result.success(null)
      }

      "stop" -> {
        tts.stop()
        result.success(null)
      }

      "setLanguage" -> {
        callOrError<String>(call, result, "language", onCall = { lang ->
          tts.setLanguage(lang)
          result.success(null)
        })
      }

      "getLanguage" -> {
        result.success(tts.getLanguage())
      }

      "getLanguages" -> {
        result.success(tts.getLanguages())
      }

      "setVoice" -> {
        callOrError<String>(call, result, "voiceId", onCall = { voiceId ->
          tts.setVoice(voiceId)
          result.success(null)
        })
      }

      "getVoices" -> {
        result.success(tts.getVoices())
      }

      "getVoicesByLanguage" -> {
        callOrError<String>(call, result, "language", onCall = { lang ->
          result.success(tts.getVoicesByLanguage(lang))
        })
      }

      "setPitch" -> {
        callOrError<Double>(call, result, "pitch", onCall = { pitch ->
          tts.setPitch(pitch.toFloat())
          result.success(null)
        })
      }

      "setRate" -> {
        callOrError<Double>(call, result, "rate", onCall = { rate ->
          tts.setRate(rate.toFloat())
          result.success(null)
        })
      }

      "setVolume" -> {
        callOrError<Double>(call, result, "volume", onCall = { volume ->
          tts.setVolume(volume.toFloat())
          result.success(null)
        })
      }

      "dispose" -> {
        tts.dispose()
        isInitialized = false
        result.success(null)
      }

      else -> {
        result.notImplemented()
      }
    }
  }

  private fun <T> callOrError(
    call: MethodCall, result: Result, argName: String, onCall: (arg: T) -> Unit
  ) {
    val arg = call.argument<T>(argName)
    if (arg == null) {
      result.error("Tts", "'$argName' argument is missing.", null)
    } else {
      onCall(arg)
    }
  }
}