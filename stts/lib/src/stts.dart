import 'package:stts_platform_interface/stts_platform_interface.dart';

class Stts extends SttsPlatform {
  @override
  Future<bool> isSupported() => SttsPlatform.instance.isSupported();

  @override
  Future<bool> hasPermission() => SttsPlatform.instance.hasPermission();

  @override
  Future<String> getLocale() => SttsPlatform.instance.getLocale();

  @override
  Future<void> setLocale(String language) {
    return SttsPlatform.instance.setLocale(language);
  }

  @override
  Future<List<String>> getSupportedLocales() {
    return SttsPlatform.instance.getSupportedLocales();
  }

  @override
  Future<void> start() => SttsPlatform.instance.start();

  @override
  Future<void> stop() => SttsPlatform.instance.stop();

  @override
  Future<void> dispose() => SttsPlatform.instance.dispose();

  @override
  Stream<SpeechState> get onStateChanged {
    return SttsPlatform.instance.onStateChanged;
  }

  @override
  Stream<String> get onResultChanged {
    return SttsPlatform.instance.onResultChanged;
  }
}
