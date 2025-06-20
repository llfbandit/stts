/// Speech recognition options.
class SttRecognitionOptions {
  /// Phrases that should be recognized, even if they are not in the system vocabulary.
  ///
  /// Characters, products, or places that are specific to your app.
  ///
  /// Keep them brief, one or two words most of the time that can be spoken without pausing.
  ///
  /// Keep also the list limited (below 100).
  ///
  /// This may not work on your platform or language, Web & Android seem to don't bias anything.
  ///
  /// Android: API 33
  final List<String> contextualStrings;

  /// Whether the speech recognition engine should increase punctuation/formatting quality of the transcription.
  ///
  /// This will likely provide more events and slow down the process.
  ///
  /// API levels: Android: 33, iOS: 16, macOS: 13
  final bool punctuation;

  /// Offline speech recognition engine usage preference.
  ///
  /// If `false`, either network or offline recognition engine may be used.
  /// - Offline engine is likely to be used if the language model is installed.
  /// - Usage can be more restrictive because of online service thresholds.
  ///
  /// This value may have no effect on Android depending of:
  /// - underlying recognizer implementation
  /// - API level < 23
  ///
  /// Supported on Android, iOS, macOS.
  final bool offline;

  /// Android specific options.
  final SttRecognitionAndroidOptions android;

  /// iOS specific options.
  final SttRecognitionIosOptions ios;

  /// macOS specific options.
  final SttRecognitionMacosOptions macos;

  const SttRecognitionOptions({
    this.contextualStrings = const [],
    this.punctuation = false,
    this.offline = true,
    this.android = const SttRecognitionAndroidOptions(),
    this.ios = const SttRecognitionIosOptions(),
    this.macos = const SttRecognitionMacosOptions(),
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'contextualStrings': contextualStrings,
      'punctuation': punctuation,
      'offline': offline,
      'android': android.toMap(),
      'ios': android.toMap(),
      'macos': android.toMap(),
    };
  }
}

/// Android specific options.
class SttRecognitionAndroidOptions {
  /// Informs the recognizer which speech model to prefer.
  final SttRecognitionAndroidModel model;

  const SttRecognitionAndroidOptions({
    this.model = SttRecognitionAndroidModel.freeForm,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'model': model.name,
    };
  }
}

/// Options for the `EXTRA_LANGUAGE_MODEL` extra.
///
/// https://developer.android.com/reference/android/speech/RecognizerIntent#EXTRA_LANGUAGE_MODEL
///
enum SttRecognitionAndroidModel {
  /// Use a language model based on free-form speech recognition.
  freeForm,

  /// Use a language model based on web search terms.
  webSearch,
}

/// iOS specific options.
class SttRecognitionIosOptions {
  /// Informs the recognizer which speech task to prefer.
  final SttRecognitionDarwinTaskHint? taskHint;

  const SttRecognitionIosOptions({
    this.taskHint,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'taskHint': taskHint,
    };
  }
}

/// macOS specific options.
class SttRecognitionMacosOptions {
  /// Informs the recognizer which speech task to prefer.
  final SttRecognitionDarwinTaskHint? taskHint;

  const SttRecognitionMacosOptions({
    this.taskHint,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'taskHint': taskHint,
    };
  }
}

/// Informs the recognizer which speech task to prefer.
///
/// SFSpeechRecognitionTaskHint
///
/// https://developer.apple.com/documentation/speech/sfspeechrecognitiontaskhint
enum SttRecognitionDarwinTaskHint {
  /// A task that uses captured speech for short, confirmation-style requests.
  confirmation,

  /// A task that uses captured speech for text entry.
  dictation,

  /// A task that uses captured speech to specify search terms.
  search,
}
