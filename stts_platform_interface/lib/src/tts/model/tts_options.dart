import 'tts_queue_mode.dart';

/// Text-to-Speech options
class TtsOptions {
  /// Queue behaviour mode (flush or add)
  final TtsQueueMode mode;

  const TtsOptions({this.mode = TtsQueueMode.add});
}
