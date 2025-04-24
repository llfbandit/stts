import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stts/stts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _stt = Stt();
  bool? _hasPermission;
  String _text = '';
  String? _error;
  StreamSubscription<SttState>? _stateSubscription;
  StreamSubscription<String>? _resultSubscription;
  bool _started = false;
  final _lang = 'fr-FR';

  @override
  void initState() {
    super.initState();

    _stt.getSupportedLocales().then((loc) {
      debugPrint('Supported locales: $loc');

      if (loc.contains(_lang)) {
        _stt.setLocale(_lang).then((_) {
          _stt.getLocale().then((lang) {
            debugPrint('Current locale: $lang');
          });
        });
      }
    });

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
      debugPrint(result);
      setState(() => _text = result);
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
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('STTS app')),
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
              Text(_error ?? ''),
            ],
          ),
        ),
      ),
    );
  }
}
