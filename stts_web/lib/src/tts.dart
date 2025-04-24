import 'dart:async';
import 'dart:js_interop';

import 'package:stts_platform_interface/stts_platform_interface.dart';
import 'package:web/web.dart';

class Tts extends TtsPlatformInterface {
  String _language = window.navigator.language;
  double _rate = 1.0; // 0.1 - 10.0
  double _volume = 1.0; // 0.0 - 1.0
  double _pitch = 1.0; // 0.0 - 2.0
  late final bool _supported;
  StreamController<TtsState>? _stateStreamCtrl;
  TtsState _state = TtsState.stop;
  var _queuedUtterances = 0;

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

    _synth.speak(utterance);
  }

  @override
  Future<void> stop() async {
    if (!_isSupported()) return;

    _synth.cancel();
    _queuedUtterances = 0;
    _updateState(TtsState.stop);
  }

  @override
  Future<void> pause() async {
    if (!_isSupported()) return;

    _synth.pause();
  }

  @override
  Future<void> resume() async {
    if (!_isSupported()) return;

    _synth.resume();
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
  Future<List<String>> getVoices() async {
    if (!_isSupported()) return [];

    final voices = _synth.getVoices().toDart;
    return voices.map((voice) => voice.name).toSet().toList(growable: false);
  }

  @override
  Future<List<String>> getVoicesByLanguage(String language) async {
    if (!_isSupported()) return [];

    final voices = _synth.getVoices().toDart;
    return voices
        .where((voice) => voice.lang == language)
        .map((voice) => voice.name)
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

    utterance.onpause = (JSAny event) {
      _updateState(TtsState.pause);
    }.toJS;

    utterance.onresume = (JSAny event) {
      _updateState(TtsState.start);
    }.toJS;

    utterance.onend = (JSAny event) {
      _queuedUtterances--;
      if (_queuedUtterances == 0) {
        _updateState(TtsState.stop);
      }
    }.toJS;

    _queuedUtterances++;

    return utterance;
  }
}
