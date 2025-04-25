import 'package:stts_platform_interface/stts_platform_interface.dart';

import 'semaphore.dart';

/// Text-to-Speech, voice synthesizer.
class Tts extends TtsPlatformInterface {
  TtsPlatformInterface get _tts => TtsPlatformInterface.instance;
  final _semaphore = Semaphore();

  @override
  Future<bool> isSupported() => _tts.isSupported();

  @override
  Future<void> start(String text) {
    if (text.isEmpty) return Future.value();

    return _safeCall(() => _tts.start(text));
  }

  @override
  Future<void> pause() => _safeCall(_tts.pause);

  @override
  Future<void> resume() => _safeCall(_tts.resume);

  @override
  Future<void> stop() => _safeCall(_tts.stop);

  @override
  Future<void> setLanguage(String language) {
    return _safeCall(() => _tts.setLanguage(language));
  }

  @override
  Future<String> getLanguage() => _safeCall(_tts.getLanguage);

  @override
  Future<List<String>> getLanguages() => _safeCall(_tts.getLanguages);

  @override
  Future<void> setVoice(String voiceName) {
    return _safeCall(() => _tts.setVoice(voiceName));
  }

  @override
  Future<List<String>> getVoices() => _safeCall(_tts.getVoices);

  @override
  Future<List<String>> getVoicesByLanguage(String language) {
    return _safeCall(() => _tts.getVoicesByLanguage(language));
  }

  @override
  Future<void> setPitch(double pitch) => _safeCall(() => _tts.setPitch(pitch));

  @override
  Future<void> setRate(double rate) => _safeCall(() => _tts.setRate(rate));

  @override
  Future<void> setVolume(double volume) {
    return _safeCall(() => _tts.setVolume(volume));
  }

  @override
  Future<void> dispose() => _safeCall(_tts.dispose);

  @override
  Stream<TtsState> get onStateChanged => _tts.onStateChanged;

  Future<T> _safeCall<T>(Future<T> Function() fn) async {
    await _semaphore.acquire();
    try {
      return await fn();
    } finally {
      _semaphore.release();
    }
  }
}
