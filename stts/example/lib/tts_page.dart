import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stts/stts.dart';

class TtsPage extends StatefulWidget {
  const TtsPage({super.key});

  @override
  State<TtsPage> createState() => _TtsPageState();
}

class _TtsPageState extends State<TtsPage> {
  final _tts = Tts();
  final _texts = [
    'Bonjour à tous!',
    'Bienvenue à cette démonstration.',
    '1 2 3, un deux trois.',
    'Cocorico!',
  ];
  final _lang = 'fr-FR';
  StreamSubscription<TtsState>? _stateSubscription;
  TtsState _ttsState = TtsState.stop;

  double _pitch = 1.0; // 0.0 - 2.0
  double _rate = 1.0; // 0.1 - 10.0
  double _volume = 1.0; // 0.0 - 1.0

  @override
  void initState() {
    super.initState();

    _tts.getLanguages().then((languages) {
      debugPrint('Supported languages: $languages');

      if (languages.contains(_lang)) {
        _tts.setLanguage(_lang).then((_) {
          _tts.getLanguage().then((lang) {
            debugPrint('Current language: $lang');
          });
        });
      }
    });

    _tts.getVoices().then((voices) {
      debugPrint('Available voices: $voices');
    });

    _tts.getVoicesByLanguage(_lang).then((voices) {
      debugPrint('Available voices for $_lang: $voices');
    });

    _stateSubscription = _tts.onStateChanged.listen(
      (ttsState) {
        setState(() => _ttsState = ttsState);
      },
      onError: (err) {
        debugPrint(err.toString());
      },
    );
  }

  @override
  void dispose() {
    super.dispose();

    _stateSubscription?.cancel();
    _tts.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Text to speech')),
        body: Center(
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pitch'),
                    SizedBox(
                      width: constraints.maxWidth / 2,
                      child: Slider(
                        value: _pitch,
                        min: 0.0,
                        max: 2.0,
                        label: _pitch.round().toString(),
                        onChanged: (double value) {
                          _tts.setPitch(value);
                          setState(() => _pitch = value);
                        },
                      ),
                    ),
                    Text(_pitch.toStringAsFixed(2)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Rate'),
                    SizedBox(
                      width: constraints.maxWidth / 2,
                      child: Slider(
                        value: _rate,
                        min: 0.1,
                        max: 10.0,
                        label: _rate.round().toString(),
                        onChanged: (double value) {
                          _tts.setRate(value);
                          setState(() => _rate = value);
                        },
                      ),
                    ),
                    Text(_rate.toStringAsFixed(2)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Volume'),
                    SizedBox(
                      width: constraints.maxWidth / 2,
                      child: Slider(
                        value: _volume,
                        min: 0.0,
                        max: 1.0,
                        label: _volume.round().toString(),
                        onChanged: (double value) {
                          _tts.setVolume(value);
                          setState(() => _volume = value);
                        },
                      ),
                    ),
                    Text(_volume.toStringAsFixed(2)),
                  ],
                ),
                SizedBox(height: 100),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_ttsState == TtsState.pause) ...[
                      TextButton(
                        onPressed: () => _tts.resume(),
                        child: Text('Resume'),
                      ),
                    ],
                    if (_ttsState == TtsState.start) ...[
                      TextButton(
                        onPressed: () => _tts.pause(),
                        child: Text('Pause'),
                      ),
                    ],
                    if (_ttsState == TtsState.stop) ...[
                      TextButton(
                        onPressed: () {
                          for (var text in _texts) {
                            _tts.start(text);
                          }
                        },
                        child: Text('Start'),
                      ),
                    ],
                    if (_ttsState == TtsState.start ||
                        _ttsState == TtsState.pause) ...[
                      TextButton(
                        onPressed: () => _tts.stop(),
                        child: Text('Stop'),
                      ),
                    ],
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
