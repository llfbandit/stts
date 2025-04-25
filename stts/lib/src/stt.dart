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
  Future<String> getLocale() => _safeCall(_stt.getLocale);

  @override
  Future<void> setLocale(String language) =>
      _safeCall(() => _stt.setLocale(language));

  @override
  Future<List<String>> getSupportedLocales() =>
      _safeCall(_stt.getSupportedLocales);

  @override
  Future<void> start() => _safeCall(_stt.start);

  @override
  Future<void> stop() => _safeCall(_stt.stop);

  @override
  Future<void> dispose() => _safeCall(_stt.dispose);

  @override
  Stream<SttState> get onStateChanged => _stt.onStateChanged;

  @override
  Stream<String> get onResultChanged => _stt.onResultChanged;

  Future<T> _safeCall<T>(Future<T> Function() fn) async {
    await _semaphore.acquire();
    try {
      return await fn();
    } finally {
      _semaphore.release();
    }
  }
}
