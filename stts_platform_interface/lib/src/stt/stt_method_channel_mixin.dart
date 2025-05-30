import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'model/ios_audio_session.dart';
import 'model/stt_recognition.dart';
import 'model/stt_recognition_options.dart';
import 'model/stt_state.dart';
import 'stt_platform_interface.dart';

/// An implementation of [SttPlatform] that uses method channels.
mixin SttMethodChannel implements SttMethodChannelPlatformInterface {
  /// The method channel used to interact with the native platform.
  final _methodChannel = const MethodChannel('com.llfbandit.stt/methods');
  _SttAndroidImpl? _android;
  _SttIosImpl? _ios;
  _SttWindowsImpl? _windows;

  @override
  Future<bool> isSupported() async {
    final result = await _methodChannel.invokeMethod<bool>('isSupported');
    return result ?? false;
  }

  @override
  Future<bool> hasPermission() async {
    final result = await _methodChannel.invokeMethod<bool>('hasPermission');
    return result ?? false;
  }

  @override
  Future<String> getLanguage() async {
    final locale = await _methodChannel.invokeMethod<String>('getLanguage');
    return locale!;
  }

  @override
  Future<void> setLanguage(String language) {
    return _methodChannel.invokeMethod<void>('setLanguage', {
      'language': language,
    });
  }

  @override
  Future<List<String>> getLanguages() async {
    final result = await _methodChannel.invokeMethod<List>(
      'getLanguages',
    );
    return result?.cast<String>() ?? [];
  }

  @override
  Future<void> start([SttRecognitionOptions? options]) {
    return _methodChannel.invokeMethod<void>('start', {
      'options': (options ?? SttRecognitionOptions()).toMap(),
    });
  }

  @override
  Future<void> stop() {
    return _methodChannel.invokeMethod<void>('stop');
  }

  @override
  Future<void> dispose() {
    return _methodChannel.invokeMethod<void>('dispose');
  }

  @override
  SttAndroid? get android {
    if (kIsWeb || TargetPlatform.android != defaultTargetPlatform) return null;

    _android ??= _SttAndroidImpl(_methodChannel);

    return _android;
  }

  @override
  SttIos? get ios {
    if (kIsWeb || TargetPlatform.iOS != defaultTargetPlatform) return null;

    _ios ??= _SttIosImpl(_methodChannel);

    return _ios;
  }

  @override
  SttWindows? get windows {
    if (kIsWeb || TargetPlatform.windows != defaultTargetPlatform) return null;

    _windows ??= _SttWindowsImpl(_methodChannel);

    return _windows;
  }
}

class _SttAndroidImpl implements SttAndroid {
  _SttAndroidImpl(this._methodChannel) {
    _methodChannel.setMethodCallHandler(_platformCallHandler);
  }

  final MethodChannel _methodChannel;
  void Function(String language, int? errCode)? _onDownloadModelEnd;

  @override
  Future<void> downloadModel(String language) {
    return _methodChannel.invokeMethod<void>('android.downloadModel', {
      'language': language,
    });
  }

  @override
  void onDownloadModelEnd(
    void Function(String language, int? errCode)? callback,
  ) {
    _onDownloadModelEnd = callback;
  }

  Future<dynamic> _platformCallHandler(MethodCall call) async {
    switch (call.method) {
      case "android.onDownloadModelEnd":
        if (_onDownloadModelEnd case final cb?) {
          final language = call.arguments['language'];
          final error = call.arguments['error'];
          cb(language, error);
        }
    }
  }

  @override
  Future<void> muteSystemSounds(bool mute) {
    return _methodChannel.invokeMethod<void>('android.muteSystemSounds', {
      'mute': mute,
    });
  }
}

class _SttIosImpl implements SttIos {
  _SttIosImpl(this._methodChannel);

  final MethodChannel _methodChannel;

  @override
  Future<void> manageAudioSession(bool manage) {
    return _methodChannel.invokeMethod<void>(
      'ios.manageAudioSession',
      manage,
    );
  }

  @override
  Future<void> setAudioSessionActive(bool active) {
    return _methodChannel.invokeMethod<void>(
      'ios.setAudioSessionActive',
      active,
    );
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
    return _methodChannel.invokeMethod<void>('ios.setAudioSessionCategory', {
      'category': category.name,
      'options': options.map((it) => it.name).toList(),
    });
  }
}

class _SttWindowsImpl implements SttWindows {
  _SttWindowsImpl(this._methodChannel);

  final MethodChannel _methodChannel;

  @override
  Future<void> showTrainingUI([
    List<String>? trainingTexts,
  ]) {
    return _methodChannel.invokeMethod<void>('windows.showTrainingUI', {
      'trainingTexts': trainingTexts,
    });
  }
}

mixin SttEventChannel implements SttEventChannelPlatformInterface {
  final _stateEventChannel = const EventChannel('com.llfbandit.stt/states');
  final _resultEventChannel = const EventChannel('com.llfbandit.stt/results');

  @override
  Stream<SttState> get onStateChanged =>
      _stateEventChannel.receiveBroadcastStream().map<SttState>(
            (state) => switch (state) {
              0 => SttState.stop,
              1 => SttState.start,
              _ => SttState.stop,
            },
          );

  @override
  Stream<SttRecognition> get onResultChanged =>
      _resultEventChannel.receiveBroadcastStream().map<SttRecognition>(
            (dynamic result) => SttRecognition(
              result['text'],
              result['isFinal'],
            ),
          );
}
