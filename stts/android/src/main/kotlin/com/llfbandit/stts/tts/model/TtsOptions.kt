package com.llfbandit.stts.tts.model

data class TtsOptions(
  val queueMode: TtsQueueMode,
  val preSilenceMs: Int?,
  val postSilenceMs: Int?
)