import 'tts_queue_mode.dart';

/// Text-to-Speech options
class TtsOptions {
  /// Queue behaviour mode (flush or add/enqueue).
  final TtsQueueMode mode;

  /// Delay (silence) before speaking the utterance.
  ///
  /// *Ignored on web platform.*
  final Duration? preSilence;

  /// Delay (silence) after speaking the utterance.
  ///
  /// *Ignored on web platform.*
  final Duration? postSilence;

  const TtsOptions({
    this.mode = TtsQueueMode.add,
    this.preSilence,
    this.postSilence,
  });
}
