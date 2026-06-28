package com.llfbandit.stts

import java.util.Locale

// Accepts "en_us", "en-us"... as "en-US".
fun parseLanguageTag(language: String): Locale {
  return Locale.forLanguageTag(language.replace('_', '-'))
}

fun normalizeLanguageTag(language: String): String {
  return parseLanguageTag(language).toLanguageTag()
}
