import 'model/tts_state.dart';
import 'model/tts_voice.dart';
import 'tts_platform.dart';

/// Text-to-Speech platform interface
abstract class TtsPlatformInterface
    implements
        TtsMethodChannelPlatformInterface,
        TtsEventChannelPlatformInterface {
  /// The default instance of [TtsPlatformInterface] to use.
  ///
  /// Defaults to [TtsPlatform].
  static TtsPlatformInterface instance = TtsPlatform();
}

/// Text-to-Speech method channel platform interface
abstract class TtsMethodChannelPlatformInterface {
  /// Checks if the platform and service is supported.
  Future<bool> isSupported() async => false;

  /// Enqueues and starts an utterance from the given [text].
  ///
  /// Refer to [onStateChanged] for accurate state.
  Future<void> start(String text);

  /// Stops and clears all utterances.
  ///
  /// Refer to [onStateChanged] for accurate state.
  Future<void> stop();

  /// Pauses current utterance.
  ///
  /// Refer to [onStateChanged] for accurate state.
  Future<void> pause();

  /// Resumes current utterance from the closest "word".
  ///
  /// Android: Below API 26, current utterance will restart.
  ///
  /// Refer to [onStateChanged] for accurate state.
  Future<void> resume();

  /// Sets language for next utterance.
  ///
  /// [language] is language code (e.g. fr-FR)
  Future<void> setLanguage(String language);

  /// Gets current language.
  Future<String> getLanguage();

  /// Returns supported languages (e.g. fr-FR).
  Future<List<String>> getLanguages();

  /// Sets voice by its ID.
  Future<void> setVoice(String voiceId);

  /// Returns supported voices.
  Future<List<TtsVoice>> getVoices();

  /// Returns voices by given [language].
  ///
  /// [language] is language code (e.g. fr-FR)
  Future<List<TtsVoice>> getVoicesByLanguage(String language);

  /// Sets tone pitch of next utterance. Range is likely 0.0 - 2.0.
  ///
  /// 1.0 is the default [pitch], lower values lower the tone, greater values increase it.
  Future<void> setPitch(double pitch);

  /// Sets speak rate of next utterance. Range is likely 0.1 - 10.0.
  ///
  /// 1.0 is the default speech [rate], (0.5 is half, 2.0 is twice, ...).
  Future<void> setRate(double rate);

  /// Sets volume of next utterance. Range is likely 0.0 - 1.0.
  ///
  /// 1.0 is the default volume.
  Future<void> setVolume(double volume);

  /// Disposes Test-to-Speech instance.
  Future<void> dispose();
}

/// Text-to-Speech event channel platform interface
abstract class TtsEventChannelPlatformInterface {
  /// Stream for receiving Text-to-Speech states and errors.
  Stream<TtsState> get onStateChanged;
}
