import 'dart:async';
import 'dart:js_interop';

import 'package:stts_platform_interface/stts_platform_interface.dart';
import 'package:web/web.dart';

class Tts extends TtsPlatformInterface {
  String _language = window.navigator.language;
  double _rate = 1.0; // 0.1 - 10.0
  SpeechSynthesisVoice? _voice;
  double _volume = 1.0; // 0.0 - 1.0
  double _pitch = 1.0; // 0.0 - 2.0
  late final bool _supported;
  StreamController<TtsState>? _stateStreamCtrl;
  TtsState _state = TtsState.stop;
  var _utteranceLastPosition = 0;
  final _utterances = <SpeechSynthesisUtterance>[];
  var _pauseRequested = false;

  Tts() {
    // Sanity check & preload languages.
    try {
      _init();
      _supported = true;
    } catch (_) {
      _supported = false;
    }
  }

  @override
  Future<bool> isSupported() async => _isSupported();

  @override
  Future<void> start(String text) async {
    if (!_isSupported()) return;

    final utterance = _addUtterance(text);

    if (_pauseRequested) {
      resume();
    } else {
      _synth.speak(utterance);
    }
  }

  @override
  Future<void> stop() async {
    if (!_isSupported()) return;

    _synth.cancel();

    _utterances.clear();
    _utteranceLastPosition = 0;
    _pauseRequested = false;

    _updateState(TtsState.stop);
  }

  @override
  Future<void> pause() async {
    if (!_isSupported()) return;

    // We don't use pause/resume from SpeechSynthesis because
    // the utterance is spoken entirely before pausing.
    _pauseRequested = true;
    _synth.cancel();
    _updateState(TtsState.pause);
  }

  @override
  Future<void> resume() async {
    if (!_isSupported()) return;

    _pauseRequested = false;
    if (_utterances.isEmpty) return;

    // Replay first utterance from last known position
    if (_utteranceLastPosition != 0) {
      final utterance = _utterances[0];
      _utterances[0].text = utterance.text.substring(
        _utteranceLastPosition.clamp(0, utterance.text.length - 1),
      );
    }

    for (var utterance in _utterances) {
      _synth.speak(utterance);
    }
  }

  @override
  Future<void> setRate(double rate) async {
    if (!_isSupported()) return;

    _rate = rate.clamp(0.1, 10.0);
  }

  @override
  Future<void> setVolume(double volume) async {
    if (!_isSupported()) return;

    _volume = volume.clamp(0.0, 1.0);
  }

  @override
  Future<void> setPitch(double pitch) async {
    if (!_isSupported()) return;

    _pitch = pitch.clamp(0.0, 2.0);
  }

  @override
  Future<void> setLanguage(String language) async {
    if (!_isSupported()) return;

    _language = language;
  }

  @override
  Future<String> getLanguage() => Future.value(_language);

  @override
  Future<List<String>> getLanguages() async {
    if (!_isSupported()) return [];

    final voices = _synth.getVoices().toDart;
    return voices.map((voice) => voice.lang).toSet().toList(growable: false);
  }

  @override
  Future<void> setVoice(String voiceId) async {
    final voices = _synth.getVoices().toDart;

    for (var voice in voices) {
      if (voice.name == voiceId) {
        _voice = voice;
        return;
      }
    }
  }

  @override
  Future<List<TtsVoice>> getVoices() async {
    if (!_isSupported()) return [];

    final voices = _synth.getVoices().toDart;
    return voices
        .map((voice) => _mapVoice(voice))
        .toSet()
        .toList(growable: false);
  }

  @override
  Future<List<TtsVoice>> getVoicesByLanguage(String language) async {
    if (!_isSupported()) return [];

    final voices = _synth.getVoices().toDart;
    return voices
        .where((voice) => voice.lang == language)
        .map((voice) => _mapVoice(voice))
        .toSet()
        .toList(growable: false);
  }

  @override
  Future<void> dispose() async {
    await stop();

    _language = window.navigator.language;
    _stateStreamCtrl?.close();
    _stateStreamCtrl = null;
  }

  @override
  Stream<TtsState> get onStateChanged {
    _stateStreamCtrl ??= StreamController.broadcast();
    return _stateStreamCtrl!.stream;
  }

  void _updateState(TtsState state) {
    final ctrl = _stateStreamCtrl;
    if (ctrl == null) {
      _state = state;
      return;
    }

    if (ctrl.hasListener && !ctrl.isClosed && _state != state) {
      ctrl.add(state);
    }

    _state = state;
  }

  void _updateStateError(Object error) {
    final ctrl = _stateStreamCtrl;
    if (ctrl == null) return;

    if (ctrl.hasListener && !ctrl.isClosed) {
      ctrl.addError(error);
    }
  }

  void _init() {
    // ignore: unused_local_variable
    final synth = _synth;
    // ignore: unused_local_variable
    final utterance = SpeechSynthesisUtterance();
  }

  bool _isSupported() {
    if (!_supported) {
      console.error('Speech synthesis not supported'.toJS);
    }

    return _supported;
  }

  SpeechSynthesis get _synth => window.speechSynthesis;

  SpeechSynthesisUtterance _addUtterance(String text) {
    final utterance = SpeechSynthesisUtterance(text)
      ..pitch = _pitch
      ..rate = _rate
      ..voice = _voice
      ..volume = _volume;

    utterance.onerror = (SpeechSynthesisErrorEvent event) {
      if (event.error == 'canceled' || event.error == 'interrupted') return;
      console.error(event.error.toJS);
      _updateStateError(event.error);
      stop();
    }.toJS;

    utterance.onstart = (JSAny event) {
      _updateState(TtsState.start);
    }.toJS;

    utterance.onend = (JSAny event) {
      // this event may be triggered even when canceling.
      if (_pauseRequested) return;

      _utterances.removeAt(0);
      if (_utterances.isEmpty) {
        _updateState(TtsState.stop);
      }
    }.toJS;

    utterance.onboundary = (SpeechSynthesisEvent event) {
      if (event.name == 'word') {
        _utteranceLastPosition = event.charIndex;
      }
    }.toJS;

    _utterances.add(utterance);

    return utterance;
  }

  TtsVoice _mapVoice(SpeechSynthesisVoice voice) {
    return TtsVoice(
      id: voice.name,
      language: voice.lang,
      languageInstalled: voice.localService,
      name: voice.name,
      networkRequired: !voice.localService,
      gender: TtsVoiceGender.unspecified,
    );
  }
}
