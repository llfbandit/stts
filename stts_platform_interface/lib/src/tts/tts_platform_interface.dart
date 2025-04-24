import 'model/tts_state.dart';
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

  /// Starts utterance of the given [text].
  Future<void> start(String text);

  /// Stops current utterance.
  Future<void> stop();

  /// Pauses current utterance.
  Future<void> pause();

  /// Resumes current utterance.
  Future<void> resume();

  /// Sets language for next utterance.
  ///
  /// [language] is language code (e.g. en-US)
  Future<void> setLanguage(String language);

  /// Gets current language.
  Future<String> getLanguage();

  /// Returns supported languages (e.g. en-US).
  Future<List<String>> getLanguages();

  /// Returns supported voices.
  Future<List<String>> getVoices();

  /// Returns voices by given [language].
  ///
  /// [language] is language code (e.g. en-US)
  Future<List<String>> getVoicesByLanguage(String language);

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
