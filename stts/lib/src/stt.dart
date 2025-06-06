import 'package:stts_platform_interface/stts_platform_interface.dart';

import 'semaphore.dart';

/// Speech-to-Text recognizer.
class Stt extends SttPlatformInterface {
  SttPlatformInterface get _stt => SttPlatformInterface.instance;
  final _semaphore = Semaphore();

  @override
  Future<bool> isSupported() => _safeCall(_stt.isSupported);

  @override
  Future<bool> hasPermission() => _safeCall(_stt.hasPermission);

  @override
  Future<String> getLanguage() => _safeCall(_stt.getLanguage);

  @override
  Future<void> setLanguage(String language) =>
      _safeCall(() => _stt.setLanguage(language));

  @override
  Future<List<String>> getLanguages() => _safeCall(_stt.getLanguages);

  @override
  Future<void> start([SttRecognitionOptions? options]) {
    return _safeCall(() => _stt.start(options));
  }

  @override
  Future<void> stop() => _safeCall(_stt.stop);

  @override
  Future<void> dispose() => _safeCall(_stt.dispose);

  @override
  Stream<SttState> get onStateChanged => _stt.onStateChanged;

  @override
  Stream<SttRecognition> get onResultChanged => _stt.onResultChanged;

  Future<T> _safeCall<T>(Future<T> Function() fn) async {
    await _semaphore.acquire();
    try {
      return await fn();
    } finally {
      _semaphore.release();
    }
  }

  @override
  SttAndroid? get android => _stt.android;

  @override
  SttIos? get ios => _stt.ios;

  @override
  SttWindows? get windows => _stt.windows;
}
