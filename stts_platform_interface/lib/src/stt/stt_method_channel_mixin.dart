import 'package:flutter/services.dart';

import 'model/stt_state.dart';
import 'stt_platform_interface.dart';

/// An implementation of [SttPlatform] that uses method channels.
mixin SttMethodChannel implements SttMethodChannelPlatformInterface {
  /// The method channel used to interact with the native platform.
  final _methodChannel = const MethodChannel('com.llfbandit.stt/methods');

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
