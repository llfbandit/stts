import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'model/speech_state.dart';
import 'stts_method_channel.dart';

abstract class SttsPlatform extends PlatformInterface {
  /// Constructs a SttsPlatform.
  SttsPlatform() : super(token: _token);

  static final Object _token = Object();

  static SttsPlatform _instance = MethodChannelStts();

  /// The default instance of [SttsPlatform] to use.
  ///
  /// Defaults to [MethodChannelStts].
  static SttsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SttsPlatform] when
  /// they register themselves.
  static set instance(SttsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Checks if the platform is supported.
  Future<bool> isSupported() async => false;

  /// Checks and requests audio microphone permission.
  Future<bool> hasPermission() {
    throw UnimplementedError('hasPermission() has not been implemented.');
  }

  /// Gets current locale for the recognizer.
  Future<String> getLocale() async {
    throw UnimplementedError(
      'getLocaleDisplayName() has not been implemented.',
    );
  }

  /// Sets current locale for the recognizer.
  Future<void> setLocale(String language) {
    throw UnimplementedError('setLocale() has not been implemented.');
  }

  /// Gets supported languages by the recognizer.
  Future<List<String>> getSupportedLocales() {
    throw UnimplementedError('getSupportedLocales() has not been implemented.');
  }

  /// Starts speech-to-text.
  Future<void> start() {
    throw UnimplementedError('start() has not been implemented.');
  }

  /// Stops speech-to-text.
  Future<void> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  /// Disposes speech-to-text recognizer.
  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }

  /// Stream for receiving speech-to-text states and errors.
  Stream<SpeechState> get onStateChanged =>
      throw UnimplementedError('onStateChanged has not been implemented.');

  /// Stream for receiving speech-to-text results.
  Stream<String> get onResultChanged =>
      throw UnimplementedError('onResultChanged has not been implemented.');
}
