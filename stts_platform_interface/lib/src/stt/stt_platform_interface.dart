import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'model/stt_state.dart';
import 'stt_platform.dart';

/// Speech-to-Text platform interface
abstract class SttPlatformInterface extends PlatformInterface
    implements
        SttMethodChannelPlatformInterface,
        SttEventChannelPlatformInterface {
  /// Constructs a SttPlatformInterface.
  SttPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  /// The default instance of [SttPlatformInterface] to use.
  ///
  /// Defaults to [SttsPlatform].
  static SttPlatformInterface instance = SttPlatform();
}

abstract class SttMethodChannelPlatformInterface {
  /// Checks if the platform is supported.
  Future<bool> isSupported() async => false;

  /// Checks and requests audio microphone permission.
  Future<bool> hasPermission();

  /// Gets current locale for the recognizer.
  Future<String> getLocale();

  /// Sets current locale for the recognizer.
  Future<void> setLocale(String language);

  /// Gets supported languages by the recognizer.
  Future<List<String>> getSupportedLocales();

  /// Starts Speech-to-Text recognizer.
  Future<void> start();

  /// Stops Speech-to-Text recognizer.
  Future<void> stop();

  /// Disposes Speech-to-Text recognizer.
  Future<void> dispose();
}

abstract class SttEventChannelPlatformInterface {
  /// Stream for receiving Speech-to-Text states and errors.
  Stream<SttState> get onStateChanged;

  /// Stream for receiving Speech-to-Text results.
  Stream<String> get onResultChanged;
}
