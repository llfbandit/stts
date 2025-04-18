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
  final _sttsPlugin = Stts();
  bool? _hasPermission;
  String _text = '';
  String? _error;
  StreamSubscription<SpeechState>? _stateSubscription;
  StreamSubscription<String>? _resultSubscription;
  bool _started = false;
  final _lang = 'fr-FR';

  @override
  void initState() {
    super.initState();

    _sttsPlugin.getSupportedLocales().then((loc) {
      debugPrint('Supported locales: $loc');

      if (loc.contains(_lang)) {
        _sttsPlugin.setLocale(_lang).then((_) {
          _sttsPlugin.getLocale().then((lang) {
            debugPrint('Current locale: $lang');
          });
        });
      }
    });

    _stateSubscription = _sttsPlugin.onStateChanged.listen(
      (speechState) {
        setState(() => _started = speechState == SpeechState.start);
      },
      onError: (err) {
        debugPrint(err.toString());
        setState(() => _error = err.toString());
      },
    );

    _resultSubscription = _sttsPlugin.onResultChanged.listen((result) {
      debugPrint(result);
      setState(() => _text = result);
    });
  }

  @override
  void dispose() {
    super.dispose();

    _stateSubscription?.cancel();
    _resultSubscription?.cancel();

    _sttsPlugin.dispose();
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
                  final result = await _sttsPlugin.hasPermission();
                  setState(() => _hasPermission = result);
                },
                child: Text('Request permission'),
              ),
              Text('Has permission: ${_hasPermission ?? 'unknown'}'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _started ? null : () => _sttsPlugin.start(),
                    child: Text('Start'),
                  ),
                  TextButton(
                    onPressed: _started
                        ? () {
                            _sttsPlugin.stop();
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
