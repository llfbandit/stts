import 'package:flutter/services.dart';

import 'model/model.dart';
import 'tts_platform_interface.dart';

/// An implementation of [TtsPlatform] that uses method channels.
mixin TtsMethodChannel implements TtsMethodChannelPlatformInterface {
  /// The method channel used to interact with the native platform.
  final _methodChannel = const MethodChannel('com.llfbandit.tts/methods');

  @override
  Future<bool> isSupported() async {
    final result = await _methodChannel.invokeMethod<bool>('isSupported');
    return result ?? false;
  }

  @override
  Future<void> start(
    String text, {
    TtsOptions options = const TtsOptions(),
  }) {
    return _methodChannel.invokeMethod<void>('start', {
      'text': text,
      'mode': options.mode.name,
    });
  }

  @override
  Future<void> stop() {
    return _methodChannel.invokeMethod<void>('stop');
  }

  @override
  Future<void> pause() {
    return _methodChannel.invokeMethod<void>('pause');
  }

  @override
  Future<void> resume() {
    return _methodChannel.invokeMethod<void>('resume');
  }

  @override
  Future<void> setLanguage(String language) {
    return _methodChannel.invokeMethod<void>('setLanguage', {
      'language': language,
    });
  }

  @override
  Future<String> getLanguage() async {
    final locale = await _methodChannel.invokeMethod<String>('getLanguage');
    return locale!;
  }

  @override
  Future<List<String>> getLanguages() async {
    final result = await _methodChannel.invokeMethod<List>(
      'getLanguages',
    );
    return result?.cast<String>() ?? [];
  }

  @override
  Future<void> setVoice(String voiceId) {
    return _methodChannel.invokeMethod<void>('setVoice', {
      'voiceId': voiceId,
    });
  }

  @override
  Future<List<TtsVoice>> getVoices() async {
    final results = await _methodChannel.invokeMethod<List>(
      'getVoices',
    );

    return results
            ?.map((d) => TtsVoice.fromMap(d as Map))
            .toList(growable: false) ??
        [];
  }

  @override
  Future<List<TtsVoice>> getVoicesByLanguage(String language) async {
    final results =
        await _methodChannel.invokeMethod<List>('getVoicesByLanguage', {
      'language': language,
    });

    return results
            ?.map((d) => TtsVoice.fromMap(d as Map))
            .toList(growable: false) ??
        [];
  }

  @override
  Future<void> setPitch(double pitch) {
    return _methodChannel.invokeMethod<void>('setPitch', {
      'pitch': pitch,
    });
  }

  @override
  Future<void> setRate(double rate) {
    return _methodChannel.invokeMethod<void>('setRate', {
      'rate': rate,
    });
  }

  @override
  Future<void> setVolume(double volume) {
    return _methodChannel.invokeMethod<void>('setVolume', {
      'volume': volume,
    });
  }

  @override
  Future<void> dispose() {
    return _methodChannel.invokeMethod<void>('dispose');
  }
}

mixin TtsEventChannel implements TtsEventChannelPlatformInterface {
  final _stateEventChannel = const EventChannel('com.llfbandit.tts/states');

  @override
  Stream<TtsState> get onStateChanged =>
      _stateEventChannel.receiveBroadcastStream().map<TtsState>(
            (state) => switch (state) {
              0 => TtsState.stop,
              1 => TtsState.start,
              2 => TtsState.pause,
              _ => TtsState.stop,
            },
          );
}
