/// TTS Voice description.
class TtsVoice {
  /// The ID used to select the device on the platform.
  final String id;

  /// Suitable spoken language.
  final String language;

  /// Flag to know is the language is installed.
  ///
  /// The download may be triggered by calling setVoice() or setLanguage() on Android.
  final bool languageInstalled;

  /// Human readable name.
  final String name;

  /// Is network required to use this voice.
  final bool networkRequired;

  /// The gender for the voice.
  final TtsVoiceGender gender;

  const TtsVoice({
    required this.id,
    required this.language,
    required this.languageInstalled,
    required this.name,
    required this.networkRequired,
    required this.gender,
  });

  /// Map voice from platform value.
  factory TtsVoice.fromMap(Map map) {
    return TtsVoice(
      id: map['id'] as String,
      language: map['language'] as String,
      languageInstalled: map['languageInstalled'] as bool,
      name: map['name'] as String,
      networkRequired: map['networkRequired'] as bool,
      gender: TtsVoiceGender.from(map['gender']),
    );
  }

  @override
  String toString() {
    return '''TtsVoice(
    id: $id,
    language: $language,
    languageInstalled: $languageInstalled,
    name: $name,
    networkRequired: $networkRequired,
    gender: $gender)
    ''';
  }
}

/// The voice gender description.
enum TtsVoiceGender {
  /// The nonspecific gender option.
  unspecified,

  /// The male voice option.
  male,

  /// The female voice option.
  female;

  /// Map gender from platform value.
  static TtsVoiceGender from(String? value) {
    return TtsVoiceGender.values.firstWhere(
      (val) => val.name == value,
      orElse: () => unspecified,
    );
  }
}
