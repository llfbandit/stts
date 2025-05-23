import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:stts_platform_interface/stts_platform_interface.dart';
import 'package:web/web.dart';

@JS('webkitSpeechRecognition')
extension type _WebkitSpeechRecognition._(SpeechRecognition _)
    implements SpeechRecognition {
  external factory _WebkitSpeechRecognition();
}

@JS('SpeechGrammarList')
extension type SpeechGrammarList._(JSObject _) implements JSObject {
  external factory SpeechGrammarList();
  external void addFromString(JSString string, [JSNumber? weight]);
}

@JS('webkitSpeechGrammarList')
extension type _WebkitSpeechGrammarList._(SpeechGrammarList _)
    implements SpeechGrammarList {
  external factory _WebkitSpeechGrammarList();
}

class Stt extends SttPlatformInterface {
  SpeechRecognition? _recognizerInstance;
  String _language = window.navigator.language;
  StreamController<SttState>? _stateStreamCtrl;
  StreamController<SttRecognition>? _resultStreamCtrl;

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
  Future<void> start([SttRecognitionOptions? options]) async {
    if (!_isSupported()) return;

    _recognizer.continuous = false;
    _recognizer.lang = _language;
    _recognizer.interimResults = true;
    _recognizer.maxAlternatives = 0;

    if (options case final options?) {
      _setRecognitionOptions(options);
    }

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
  Stream<SttRecognition> get onResultChanged {
    _resultStreamCtrl ??= StreamController.broadcast();
    return _resultStreamCtrl!.stream;
  }

  ///////////////////////////////////////////////////////
  // Private section
  ///////////////////////////////////////////////////////

  SpeechRecognition get _recognizer {
    _recognizerInstance ??= _createSpeechRecognition();
    assert(_recognizerInstance != null, 'SpeechRecognition is not supported.');

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

  void _updateResult(String text, bool isFinal) {
    final ctrl = _resultStreamCtrl;
    if (ctrl == null) return;

    if (ctrl.hasListener && !ctrl.isClosed) {
      ctrl.add(SttRecognition(text, isFinal));
    }
  }

  bool _isSupported() {
    try {
      return _createSpeechRecognition() != null;
    } catch (_) {
      return false;
    }
  }

  void _stop() {
    if (!_isSupported()) return;

    _recognizerInstance?.stop();
    _recognizerInstance = null;

    _updateState(SttState.stop);
  }

  void _setRecognitionOptions(SttRecognitionOptions options) {
    if (options.contextualStrings.isNotEmpty) {
      final grammars = _createGrammarList();

      if (grammars != null) {
        final grammarsString = StringBuffer('#JSGF V1.0; ')
          ..write('grammar values; ')
          ..write('public <value> = ')
          ..write(options.contextualStrings.join(' | '))
          ..write(' ;');

        grammars.addFromString(grammarsString.toString().toJS, 1.toJS);
        _recognizer.grammars = grammars;
      }
    }
  }

  SpeechGrammarList? _createGrammarList() {
    if (window.hasProperty('webkitSpeechGrammarList'.toJS).toDart) {
      return _WebkitSpeechGrammarList();
    } else if (window.hasProperty('SpeechGrammarList'.toJS).toDart) {
      return SpeechGrammarList();
    }

    return null;
  }

  SpeechRecognition? _createSpeechRecognition() {
    if (window.hasProperty('webkitSpeechRecognition'.toJS).toDart) {
      return _WebkitSpeechRecognition();
    } else if (window.hasProperty('SpeechRecognition'.toJS).toDart) {
      return SpeechRecognition();
    }

    return null;
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

    _updateResult(
      recognitionResult.item(0).transcript,
      recognitionResult.isFinal,
    );
  }

  @override
  SttAndroid? get android => null;

  @override
  SttIos? get ios => null;

  @override
  SttWindows? get windows => null;
}
