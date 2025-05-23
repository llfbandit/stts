import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stts/stts.dart';

class SttPage extends StatefulWidget {
  const SttPage({super.key});

  @override
  State<SttPage> createState() => _SttPageState();
}

class _SttPageState extends State<SttPage> {
  final _stt = Stt();
  bool? _hasPermission;
  String _text = '';
  String? _error;
  StreamSubscription<SttState>? _stateSubscription;
  StreamSubscription<SttRecognition>? _resultSubscription;
  bool _started = false;
  final _lang = 'fr-FR';

  @override
  void initState() {
    super.initState();

    _stt.isSupported().then((supported) {
      debugPrint('Supported: $supported');
    });

    _stt.getLanguages().then((loc) {
      debugPrint('Supported languages: $loc');

      if (loc.contains(_lang)) {
        _stt.setLanguage(_lang).then((_) {
          _stt.getLanguage().then((lang) {
            debugPrint('Current language: $lang');
          });
        });
      }
    });

    // _stt.android?.onDownloadModelEnd(
    //   (language, errCode) {
    //     debugPrint('Language DL: $language, error: $errCode');
    //   },
    // );
    // _stt.android?.downloadModel('nb-NO');

    // _stt.android?.muteSystemSounds(true);

    // _stt.ios?.manageAudioSession(true);
    // _stt.ios?.setAudioSessionCategory();
    // _stt.ios?.setAudioSessionActive(true);

    _stateSubscription = _stt.onStateChanged.listen(
      (sttState) {
        setState(() => _started = sttState == SttState.start);
      },
      onError: (err) {
        debugPrint(err.toString());
        setState(() => _error = err.toString());
      },
    );

    _resultSubscription = _stt.onResultChanged.listen((result) {
      debugPrint('${result.text} (isFinal: ${result.isFinal})');
      setState(() => _text = result.text);
    });
  }

  @override
  void dispose() {
    super.dispose();

    _stateSubscription?.cancel();
    _resultSubscription?.cancel();

    _stt.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speech to text')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () async {
                final result = await _stt.hasPermission();
                setState(() => _hasPermission = result);
              },
              child: Text('Request permission'),
            ),
            Text('Has permission: ${_hasPermission ?? 'unknown'}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _started ? null : () => _stt.start(),
                  child: Text('Start'),
                ),
                TextButton(
                  onPressed: _started
                      ? () {
                          _stt.stop();
                          setState(() {
                            _text = '';
                            _error = null;
                          });
                        }
                      : null,
                  child: Text('Stop'),
                ),
              ],
            ),
            Expanded(child: Text(_text)),
            if (defaultTargetPlatform == TargetPlatform.windows) ...[
              TextButton(
                onPressed: _started
                    ? null
                    : () => _stt.windows?.showTrainingUI(['Bonjour']),
                child: Text('Show training UI'),
              ),
            ],
            Text(_error ?? ''),
          ],
        ),
      ),
    );
  }
}
