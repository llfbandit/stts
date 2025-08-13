package com.llfbandit.stts.stt.model

import android.speech.RecognizerIntent

class SttRecognitionOptions(
  val contextualStrings: ArrayList<String> = ArrayList(),
  val punctuation: Boolean = false,
  val model: String,
  val offline: Boolean = true
) {
  companion object {
    fun fromMap(options: Map<String, Any>, hasLanguages: Boolean): SttRecognitionOptions {
      var contextualStrings = ArrayList<String>()
      val value = options["contextualStrings"]
      if (value is ArrayList<*> && value.all { it is String }) {
        @Suppress("UNCHECKED_CAST")
        contextualStrings = value as ArrayList<String>
      }

      val model = when ((options["android"] as Map<*, *>)["model"] as String) {
        "freeForm" -> RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
        else -> RecognizerIntent.LANGUAGE_MODEL_WEB_SEARCH
      }

      val punctuation =
        if (options["punctuation"] != null) options["punctuation"] as Boolean else false

      // Override
      val offline = if (hasLanguages && options["offline"] != null)
        options["offline"] as Boolean
      else
        hasLanguages

      return SttRecognitionOptions(
        contextualStrings,
        punctuation,
        model,
        offline
      )
    }
  }
}
