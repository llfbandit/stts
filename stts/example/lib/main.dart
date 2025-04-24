import 'package:flutter/material.dart';
import 'package:stts_example/stt_page.dart';
import 'package:stts_example/tts_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: <String, WidgetBuilder>{
        '/stt': (BuildContext context) => const SttPage(),
        '/tts': (BuildContext context) => const TtsPage(),
      },
      home: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(title: const Text('STTS app')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/stt');
                  },
                  child: Text('Speech to text'),
                ),
                SizedBox(height: 50),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/tts');
                  },
                  child: Text('Text to speech'),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
