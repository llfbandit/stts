import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:stts_platform_interface/stts_platform_interface.dart';
import 'package:web/web.dart';

// Remove this when fixed (#276)[https://github.com/dart-lang/web/issues/276].
// There's an issue on release mode with missing polyfill and webkit renaming.
@JS('webkitSpeechRecognition')
extension type _SpeechRecognition._(SpeechRecognition _)
    implements SpeechRecognition {
  external factory _SpeechRecognition();
}

class Stt extends SttPlatformInterface {
  SpeechRecognition? _recognizerInstance;
  String _language = window.navigator.language;
  StreamController<SttState>? _stateStreamCtrl;
  StreamController<String>? _resultStreamCtrl;

  @override
  Future<bool> isSupported() async => _isSupported();

  // There's no permission to request but starting recognition...
  @override
  Future<bool> hasPermission() => isSupported();

  @override
  Future<String> getLanguage() async => _language;

  @override
  Future<void> setLanguage(String language) async => _language = language;

  // There's no feature to retrieve the supported languages.
  // Provide the default value from the recognizer if any.
  @override
  Future<List<String>> getLanguages() async {
    if (!_isSupported()) return [];

    final lang = _recognizer.lang;
    if (lang.isNotEmpty) {
      return [lang];
    }

    return [];
  }

  @override
  Future<void> start() async {
    if (!_isSupported()) return;

    _recognizer.continuous = false;
    _recognizer.lang = _language;
    _recognizer.interimResults = true;
    _recognizer.maxAlternatives = 0;

    _recognizer.onerror = _onError.toJS;
    _recognizer.onstart = _onStart.toJS;
    _recognizer.onend = _onEnd.toJS;
    _recognizer.onnomatch = _onNoMatch.toJS;
    _recognizer.onresult = _onResult.toJS;

    _recognizer.start();
  }

  @override
  Future<void> stop() async => _stop();

  @override
  Future<void> dispose() async {
    await _stateStreamCtrl?.close();
    _stateStreamCtrl = null;

    await _resultStreamCtrl?.close();
    _resultStreamCtrl = null;

    _recognizerInstance?.stop();
    _recognizerInstance = null;
  }

  @override
  Stream<SttState> get onStateChanged {
    _stateStreamCtrl ??= StreamController.broadcast();
    return _stateStreamCtrl!.stream;
  }

  @override
  Stream<String> get onResultChanged {
    _resultStreamCtrl ??= StreamController.broadcast();
    return _resultStreamCtrl!.stream;
  }

  ///////////////////////////////////////////////////////
  // Private section
  ///////////////////////////////////////////////////////

  SpeechRecognition get _recognizer {
    _recognizerInstance ??= _SpeechRecognition();
    return _recognizerInstance!;
  }

  void _updateState(SttState state) {
    final ctrl = _stateStreamCtrl;
    if (ctrl == null) return;

    if (ctrl.hasListener && !ctrl.isClosed) {
      ctrl.add(state);
    }
  }

  void _updateStateError(Object error) {
    final ctrl = _stateStreamCtrl;
    if (ctrl == null) return;

    if (ctrl.hasListener && !ctrl.isClosed) {
      ctrl.addError(error);
    }
  }

  void _updateResult(String result) {
    final ctrl = _resultStreamCtrl;
    if (ctrl == null) return;

    if (ctrl.hasListener && !ctrl.isClosed) {
      ctrl.add(result);
    }
  }

  bool _isSupported() {
    return window.hasProperty('SpeechRecognition'.toJS).toDart ||
        window.hasProperty('webkitSpeechRecognition'.toJS).toDart;
  }

  void _stop() {
    if (!_isSupported()) return;

    _recognizer.stop();
    _updateState(SttState.stop);
  }

  ///////////////////////////////////////////////////////
  // SpeechRecognition events
  ///////////////////////////////////////////////////////

  void _onError(SpeechRecognitionErrorEvent event) {
    _updateStateError(event.error);
  }

  void _onStart(Event event) => _updateState(SttState.start);

  void _onEnd(Event event) => _stop();

  void _onNoMatch(Event event) => _stop();

  void _onResult(SpeechRecognitionEvent event) {
    final results = event.results;
    if (results.length == 0) return;

    final recognitionResult = results.item(0);
    if (recognitionResult.length == 0) return;

    recognitionResult.item(0).transcript;

    _updateResult(recognitionResult.item(0).transcript);
  }

  @override
  SttAndroid? get android => null;

  @override
  SttWindows? get windows => null;
}
