import 'model/tts_state.dart';
import 'model/tts_voice.dart';
import 'tts_platform.dart';

abstract class TtsPlatformInterface
    implements
        TtsMethodChannelPlatformInterface,
        TtsEventChannelPlatformInterface {
  /// The default instance of [TtsPlatformInterface] to use.
  ///
  /// Defaults to [TtsPlatform].
  static TtsPlatformInterface instance = TtsPlatform();
}

abstract class TtsMethodChannelPlatformInterface {
  /// Checks if the platform is supported.
  Future<bool> isSupported() async => false;

  /// Enqueue and starts utterance of the given [text].
  Future<void> start(String text);

  /// Stops and clear all utterances.
  Future<void> stop();

  /// Pauses current utterance.
  Future<void> pause();

  /// Resumes current utterance.
  ///
  /// Android: Below API 26, utterance will restart. Otherwise, text is resumed from the closest "word".
  Future<void> resume();

  /// Sets language for next utterance.
  ///
  /// [language] is language code (e.g. en-US)
  Future<void> setLanguage(String language);

  /// Gets current language.
  Future<String> getLanguage();

  /// Returns supported languages (e.g. en-US).
  Future<List<String>> getLanguages();

  /// Sets voice by its ID.
  Future<void> setVoice(String voiceId);

  /// Returns supported voices.
  Future<List<TtsVoice>> getVoices();

  /// Returns voices by given [language].
  ///
  /// [language] is language code (e.g. en-US)
  Future<List<TtsVoice>> getVoicesByLanguage(String language);

  /// Sets tone pitch of next utterance.
  ///
  /// 1.0 is the normal [pitch], lower values lower the tone, greater values increase it.
  Future<void> setPitch(double pitch);

  /// Sets speak rate of next utterance.
  ///
  /// 1.0 is the normal speech [rate], (0.5 is half, 2.0 is twice, ...).
  Future<void> setRate(double rate);

  /// Sets volume of next utterance.
  ///
  /// Volume is from 0 to 1 where 0 is silence, and 1 is the maximum volume (default).
  Future<void> setVolume(double volume);

  /// Disposes Test-to-Speech instance.
  Future<void> dispose();
}

abstract class TtsEventChannelPlatformInterface {
  /// Stream for receiving Text-to-Speech states and errors.
  Stream<TtsState> get onStateChanged;
}
