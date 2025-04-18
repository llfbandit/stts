import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'model/speech_state.dart';
import 'stts_platform_interface.dart';

/// An implementation of [SttsPlatform] that uses method channels.
class MethodChannelStts extends SttsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('stts');

  final _stateEventChannel = const EventChannel('com.llfbandit.stts/states');
  final _resultEventChannel = const EventChannel('com.llfbandit.stts/results');

  @override
  Future<bool> isSupported() async {
    final result = await methodChannel.invokeMethod<bool>('isSupported');
    return result ?? false;
  }

  @override
  Future<bool> hasPermission() async {
    final result = await methodChannel.invokeMethod<bool>('hasPermission');
    return result ?? false;
  }

  @override
  Future<String> getLocale() async {
    final locale = await methodChannel.invokeMethod<String>('getLocale');
    return locale!;
  }

  @override
  Future<void> setLocale(String language) {
    return methodChannel.invokeMethod<void>('setLocale', {
      'language': language,
    });
  }

  @override
  Future<List<String>> getSupportedLocales() async {
    final result = await methodChannel.invokeMethod<List>(
      'getSupportedLocales',
    );
    return result?.cast<String>() ?? [];
  }

  @override
  Future<void> start() {
    return methodChannel.invokeMethod<void>('start');
  }

  @override
  Future<void> stop() {
    return methodChannel.invokeMethod<void>('stop');
  }

  @override
  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }

  @override
  Stream<SpeechState> get onStateChanged =>
      _stateEventChannel.receiveBroadcastStream().map<SpeechState>(
            (state) => switch (state) {
              0 => SpeechState.stop,
              1 => SpeechState.start,
              _ => SpeechState.stop,
            },
          );

  @override
  Stream<String> get onResultChanged => _resultEventChannel
      .receiveBroadcastStream()
      .map<String>((dynamic result) => result as String);
}
