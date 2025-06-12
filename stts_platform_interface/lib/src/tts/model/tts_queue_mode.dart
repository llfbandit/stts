/// Text-to-Speech queue behaviour modes
enum TtsQueueMode {
  /// Cancels all current & next utterances
  /// and replaces to the given one.
  flush,

  /// Adds an utterance to the current queue with the given text.
  add,
}
