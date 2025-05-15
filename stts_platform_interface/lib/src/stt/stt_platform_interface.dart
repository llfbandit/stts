import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'model/stt_recognition.dart';
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

/// Speech-to-Text method channel platform interface
abstract class SttMethodChannelPlatformInterface {
  /// Checks if the platform and service is supported.
  Future<bool> isSupported() async => false;

  /// Checks and requests audio microphone permission.
  Future<bool> hasPermission();

  /// Gets current language for the recognizer (e.g. en-US).
  Future<String> getLanguage();

  /// Sets current language for the recognizer (e.g. en-US).
  Future<void> setLanguage(String language);

  /// Gets supported languages by the recognizer (e.g. en-US).
  Future<List<String>> getLanguages();

  /// Starts speech recognition.
  ///
  /// Refer to [onStateChanged] for accurate state.
  Future<void> start();

  /// Stops speech recognition.
  ///
  /// Refer to [onStateChanged] for accurate state.
  Future<void> stop();

  /// Disposes speech recognition.
  Future<void> dispose();

  /// Android platform specific methods.
  ///
  /// Returns [null] when not on Android platform.
  SttAndroid? get android;

  /// Windows platform specific methods.
  ///
  /// Returns [null] when not on Windows platform.
  SttWindows? get windows;
}

/// Android platform specific methods.
abstract class SttAndroid {
  /// Download model for given [language] (e.g. en-US).
  ///
  /// This might trigger user interaction to approve the download.
  ///
  /// Useful for offline usage. API 34+.
  Future<void> downloadModel(String language);

  /// Callback for [downloadModel] method when download finished.
  ///
  /// [errCode] is null on success. Otherwise check ERROR_* constants.
  /// https://developer.android.com/reference/android/speech/SpeechRecognizer#constants_1
  void onDownloadModelEnd(
    void Function(String language, int? errCode)? callback,
  );

  /// Mute default system beep sounds when starting and stopping speech recognition.
  Future<void> muteSystemSounds(bool mute);
}

/// Windows platform specific methods.
abstract class SttWindows {
  /// Shows system training UI dialog.
  ///
  /// By default, speech recognition can be very inaccurate.
  /// This dialog helps to improve recognition with your own voice.
  ///
  /// [trainingTexts]: Custom training sentences.
  /// If null, system will propose automatically training texts.
  Future<void> showTrainingUI([List<String>? trainingTexts]);
}

/// Speech-to-Text event channel platform interface
abstract class SttEventChannelPlatformInterface {
  /// Stream for receiving Speech-to-Text states and errors.
  Stream<SttState> get onStateChanged;

  /// Stream for receiving Speech-to-Text results.
  Stream<SttRecognition> get onResultChanged;
}
