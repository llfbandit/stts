import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'model/stt_state.dart';
import 'stt_platform_interface.dart';

/// An implementation of [SttPlatform] that uses method channels.
mixin SttMethodChannel implements SttMethodChannelPlatformInterface {
  /// The method channel used to interact with the native platform.
  final _methodChannel = const MethodChannel('com.llfbandit.stt/methods');
  _SttAndroidImpl? _android;
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
  Future<void> start() {
    return _methodChannel.invokeMethod<void>('start');
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
    if (kIsWeb || !Platform.isAndroid) return null;

    _android ??= _SttAndroidImpl(_methodChannel);

    return _android;
  }

  @override
  SttWindows? get windows {
    if (kIsWeb || !Platform.isWindows) return null;

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
    return _methodChannel.invokeMethod<void>('downloadModel', {
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
      case "onDownloadModelEnd":
        if (_onDownloadModelEnd case final cb?) {
          final language = call.arguments['language'];
          final error = call.arguments['error'];
          cb(language, error);
        }
    }
  }
}

class _SttWindowsImpl implements SttWindows {
  _SttWindowsImpl(this._methodChannel);

  final MethodChannel _methodChannel;

  @override
  Future<void> showTrainingUI([
    List<String>? trainingTexts,
  ]) {
    return _methodChannel.invokeMethod<void>('showTrainingUI', {
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
  Stream<String> get onResultChanged => _resultEventChannel
      .receiveBroadcastStream()
      .map<String>((dynamic result) => result as String);
}
