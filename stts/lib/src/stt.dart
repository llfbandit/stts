import 'package:stts_platform_interface/stts_platform_interface.dart';

class Stt extends SttPlatformInterface {
  SttPlatformInterface get _instance => SttPlatformInterface.instance;

  @override
  Future<bool> isSupported() => _instance.isSupported();

  @override
  Future<bool> hasPermission() => _instance.hasPermission();

  @override
  Future<String> getLocale() => _instance.getLocale();

  @override
  Future<void> setLocale(String language) {
    return _instance.setLocale(language);
  }

  @override
  Future<List<String>> getSupportedLocales() {
    return _instance.getSupportedLocales();
  }

  @override
  Future<void> start() => _instance.start();

  @override
  Future<void> stop() => _instance.stop();

  @override
  Future<void> dispose() => _instance.dispose();

  @override
  Stream<SttState> get onStateChanged {
    return _instance.onStateChanged;
  }

  @override
  Stream<String> get onResultChanged {
    return _instance.onResultChanged;
  }
}
