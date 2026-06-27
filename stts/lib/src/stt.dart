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

  // Runs platform calls one at a time. Native implementations rely on it.
  Future<T> _safeCall<T>(Future<T> Function() fn) async {
    await _semaphore.acquire();
    try {
      return await fn();
    } finally {
      _semaphore.release();
    }
  }

  @override
  SttAndroid? get android {
    final android = _stt.android;
    return android != null ? _SttAndroid(android, _safeCall) : null;
  }

  @override
  SttIos? get ios {
    final ios = _stt.ios;
    return ios != null ? _SttIos(ios, _safeCall) : null;
  }

  @override
  SttWindows? get windows {
    final windows = _stt.windows;
    return windows != null ? _SttWindows(windows, _safeCall) : null;
  }
}

typedef _SafeCall = Future<T> Function<T>(Future<T> Function() fn);

class _SttAndroid implements SttAndroid {
  _SttAndroid(this._android, this._safeCall);

  final SttAndroid _android;
  final _SafeCall _safeCall;

  @override
  Future<void> downloadModel(String language) {
    return _safeCall(() => _android.downloadModel(language));
  }

  @override
  void onDownloadModelEnd(
    void Function(String language, int? errCode)? callback,
  ) {
    _android.onDownloadModelEnd(callback);
  }

  @override
  Future<void> muteSystemSounds(bool mute) {
    return _safeCall(() => _android.muteSystemSounds(mute));
  }
}

class _SttIos implements SttIos {
  _SttIos(this._ios, this._safeCall);

  final SttIos _ios;
  final _SafeCall _safeCall;

  @override
  Future<void> manageAudioSession(bool manage) {
    return _safeCall(() => _ios.manageAudioSession(manage));
  }

  @override
  Future<void> setAudioSessionActive(bool active) {
    return _safeCall(() => _ios.setAudioSessionActive(active));
  }

  @override
  Future<void> setAudioSessionCategory({
    IosAudioCategory category = IosAudioCategory.playAndRecord,
    List<IosAudioCategoryOptions> options = const [
      IosAudioCategoryOptions.duckOthers,
      IosAudioCategoryOptions.defaultToSpeaker,
      IosAudioCategoryOptions.allowBluetooth,
      IosAudioCategoryOptions.allowBluetoothA2DP,
    ],
  }) {
    return _safeCall(
      () => _ios.setAudioSessionCategory(category: category, options: options),
    );
  }
}

class _SttWindows implements SttWindows {
  _SttWindows(this._windows, this._safeCall);

  final SttWindows _windows;
  final _SafeCall _safeCall;

  @override
  Future<void> showTrainingUI([List<String>? trainingTexts]) {
    return _safeCall(() => _windows.showTrainingUI(trainingTexts));
  }
}
