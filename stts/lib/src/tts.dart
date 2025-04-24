import 'package:stts_platform_interface/stts_platform_interface.dart';

/// Text-to-Speech, voice synthesizer.
class Tts extends TtsPlatformInterface {
  TtsPlatformInterface get _tts => TtsPlatformInterface.instance;

  @override
  Future<bool> isSupported() => _tts.isSupported();

  @override
  Future<void> start(String text) => _tts.start(text);

  @override
  Future<void> pause() => _tts.pause();

  @override
  Future<void> resume() => _tts.resume();

  @override
  Future<void> stop() => _tts.stop();

  @override
  Future<void> setLanguage(String language) => _tts.setLanguage(language);

  @override
  Future<String> getLanguage() => _tts.getLanguage();

  @override
  Future<List<String>> getLanguages() => _tts.getLanguages();

  @override
  Future<List<String>> getVoices() => _tts.getVoices();

  @override
  Future<List<String>> getVoicesByLanguage(String language) {
    return _tts.getVoicesByLanguage(language);
  }

  @override
  Future<void> setPitch(double pitch) => _tts.setPitch(pitch);

  @override
  Future<void> setRate(double rate) => _tts.setRate(rate);

  @override
  Future<void> setVolume(double volume) => _tts.setVolume(volume);

  @override
  Future<void> dispose() => _tts.dispose();

  @override
  Stream<TtsState> get onStateChanged => _tts.onStateChanged;
}
