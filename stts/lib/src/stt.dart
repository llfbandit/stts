import 'package:stts_platform_interface/stts_platform_interface.dart';

/// Speech-to-Text recognizer.
class Stt extends SttPlatformInterface {
  SttPlatformInterface get _stt => SttPlatformInterface.instance;

  @override
  Future<bool> isSupported() => _stt.isSupported();

  @override
  Future<bool> hasPermission() => _stt.hasPermission();

  @override
  Future<String> getLocale() => _stt.getLocale();

  @override
  Future<void> setLocale(String language) => _stt.setLocale(language);

  @override
  Future<List<String>> getSupportedLocales() => _stt.getSupportedLocales();

  @override
  Future<void> start() => _stt.start();

  @override
  Future<void> stop() => _stt.stop();

  @override
  Future<void> dispose() => _stt.dispose();

  @override
  Stream<SttState> get onStateChanged => _stt.onStateChanged;

  @override
  Stream<String> get onResultChanged => _stt.onResultChanged;
}
