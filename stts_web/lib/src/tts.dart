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
  Future<void>? _voicesReady;

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
  Future<void> start(
    String text, {
    TtsOptions options = const TtsOptions(),
  }) async {
    if (!_isSupported()) return;

    if (options.mode == TtsQueueMode.flush) {
      _stop();
    }

    final utterance = _addUtterance(text);

    if (_pauseRequested) {
      resume();
    } else {
      _synth.speak(utterance);
    }
  }

  @override
  Future<void> stop() async {
    _stop();

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
    if (!_isSupported() || !_pauseRequested) return;

    _pauseRequested = false;
    if (_utterances.isEmpty) return;

    // Replay first utterance from last known position
    final first = _utterances[0];
    final position = _utteranceLastPosition.clamp(0, first.text.length);
    // Boundaries now count from the text we cut.
    _utteranceLastPosition = 0;

    // Cancelled utterances may still report events.
    // Speak copies to tell them apart.
    for (var i = 0; i < _utterances.length; i++) {
      final utterance = _utterances[i];
      _utterances[i] = _createUtterance(
        i == 0 ? utterance.text.substring(position) : utterance.text,
        from: utterance,
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

    // Keep the voice when it already speaks this language.
    if (_voice?.lang.toLowerCase() == language.toLowerCase()) return;

    // Set first matching voice. Without one, the browser picks it from utterance language.
    _voice = null;
    for (var voice in await _loadVoices()) {
      if (voice.lang.toLowerCase() == language.toLowerCase()) {
        _voice = voice;
        return;
      }
    }
  }

  @override
  Future<String> getLanguage() => Future.value(_language);

  @override
  Future<List<String>> getLanguages() async {
    if (!_isSupported()) return [];

    final voices = await _loadVoices();
    return voices.map((voice) => voice.lang).toSet().toList(growable: false);
  }

  @override
  Future<void> setVoice(String voiceId) async {
    if (!_isSupported()) return;

    final voices = await _loadVoices();

    for (var voice in voices) {
      if (voice.name == voiceId) {
        _voice = voice;
        _language = voice.lang;
        return;
      }
    }
  }

  @override
  Future<List<TtsVoice>> getVoices() async {
    if (!_isSupported()) return [];

    final voices = await _loadVoices();
    return voices
        .map((voice) => _mapVoice(voice))
        .toSet()
        .toList(growable: false);
  }

  @override
  Future<List<TtsVoice>> getVoicesByLanguage(String language) async {
    if (!_isSupported()) return [];

    final voices = await _loadVoices();
    return voices
        .where((voice) => voice.lang == language)
        .map((voice) => _mapVoice(voice))
        .toSet()
        .toList(growable: false);
  }

  @override
  Future<void> dispose() async {
    await stop();

    // State stream stays open, the instance may be used again as on other platforms.
    _language = window.navigator.language;
    _voice = null;
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

  /// Stops synth and resets variable members with out firing stop event.
  void _stop() {
    if (!_isSupported()) return;

    _synth.cancel();

    _utterances.clear();
    _utteranceLastPosition = 0;
    _pauseRequested = false;
  }

  SpeechSynthesis get _synth => window.speechSynthesis;

  /// Gets the voices, waiting for the browser to load them if needed.
  Future<List<SpeechSynthesisVoice>> _loadVoices() async {
    var voices = _synth.getVoices().toDart;

    if (voices.isEmpty) {
      // Chrome fills the list asynchronously. Wait for it once.
      _voicesReady ??= _awaitVoices();
      await _voicesReady;

      voices = _synth.getVoices().toDart;
    }

    return voices;
  }

  Future<void> _awaitVoices() {
    final completer = Completer<void>();

    // Don't take over onvoiceschanged, the app may use it.
    final onChanged = (Event event) {
      if (!completer.isCompleted) completer.complete();
    }.toJS;
    _synth.addEventListener('voiceschanged', onChanged);

    // Give up when the browser has no voice to report.
    return completer.future
        .timeout(const Duration(seconds: 2), onTimeout: () {})
        .whenComplete(
          () => _synth.removeEventListener('voiceschanged', onChanged),
        );
  }

  SpeechSynthesisUtterance _addUtterance(String text) {
    final utterance = _createUtterance(text);
    _utterances.add(utterance);

    return utterance;
  }

  // Settings are taken from [from] when given, or from current ones.
  SpeechSynthesisUtterance _createUtterance(
    String text, {
    SpeechSynthesisUtterance? from,
  }) {
    final utterance = SpeechSynthesisUtterance(text)
      ..lang = from?.lang ?? _language
      ..pitch = from?.pitch ?? _pitch
      ..rate = from?.rate ?? _rate
      ..voice = from != null ? from.voice : _voice
      ..volume = from?.volume ?? _volume;

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

      // Cancelled utterances fire it too. Skip the ones we dropped.
      if (_utterances.isEmpty || !identical(_utterances.first, utterance)) {
        return;
      }

      _utterances.removeAt(0);

      // The position belongs to the utterance we just dropped.
      _utteranceLastPosition = 0;

      if (_utterances.isEmpty) {
        _updateState(TtsState.stop);
      }
    }.toJS;

    utterance.onboundary = (SpeechSynthesisEvent event) {
      // The position belongs to the utterance being spoken.
      if (_utterances.isEmpty || !identical(_utterances.first, utterance)) {
        return;
      }

      if (event.name == 'word') {
        _utteranceLastPosition = event.charIndex;
      }
    }.toJS;

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
