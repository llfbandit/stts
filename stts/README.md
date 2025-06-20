# stts

Speech-to-Text (STT) and Text-to-Speech (TTS) Flutter plugin.

No dependency. All implementations use what the platform provides.

## Platform Speech-to-Text parity matrix
| Feature             | Android       | iOS          | macOS        | web      | Windows     
|---------------------|---------------|--------------|--------------|----------|---------
| permission          | ✔️            |   ✔️        | ✔️           | ✔️      |     
| language selection  | ✔️            |   ✔️        | ✔️           | ✔️      | ✔️    
| punctuation         | ✔️            |   ✔️        | ✔️           |         |
| grammars            | ✔️*            |   ✔️        | ✔️           | ✔️*      |
- *: seems to do nothing.
- Specific platform features are not listed here.

## Platform Text-to-Speech parity matrix
| Feature             | Android       | iOS          | macOS           | web       | Windows     
|---------------------|---------------|--------------|-----------------|-----------|---------
| pause/resume        | ✔️            | ✔️          | ✔️             | ✔️        | ✔️     
| language selection  | ✔️            | ✔️          | ✔️             | ✔️        | ✔️    
| voice selection     | ✔️            | ✔️          | ✔️             | ✔️        | ✔️    
| pitch               | ✔️            | ✔️          | ✔️             | ✔️        | ✔️    
| rate                | ✔️            | ✔️          | ✔️             | ✔️        | ✔️    
| volume              | ✔️            | ✔️          | ✔️             | ✔️        | ✔️     

## Usage of Speech-to-Text
```dart
import 'package:stts/stts.dart';

final stt = Stt();

// Get state changes
final sub = stt.onStateChanged.listen(
  (speechState) { /* SttState.start/stop */ },
  onError: (err) {/* Retrieve listener errors from here */ },
);

await tts.hasPermission(); // Request for audio recording and STT service usage.

// Get intermediate and final results.
stt.onResultChanged.listen((result) { /* The current result String */ });

// Start speech recognition.
stt.start(); // ...optionnaly, abort with stt.stop();

// As always, don't forget to release resources.
sub.cancel();
stt.dispose();
```

## Usage of Text-to-Speech
```dart
import 'package:stts/stts.dart';

final tts = Tts();

// Get state changes
final sub = tts.onStateChanged.listen(
  (ttsState) { /* TtsState.start/stop/pause */ },
  onError: (err) { /* Retrieve listener errors from here */ },
);

// Add utterance. Texts are queued.
tts.start('Hello');
tts.start('world!'); // ...optionnaly, abort with tts.stop();

// As always, don't forget to release resources.
sub.cancel();
tts.dispose();
```

## Platforms setup & infos

You can either use one or both engines in your app. So permissions are only required for dedicated engine.

* [Android](https://github.com/llfbandit/stts/blob/master/doc/README_android.md)
* [iOS](https://github.com/llfbandit/stts/blob/master/doc/README_ios.md)
* [macOS](https://github.com/llfbandit/stts/blob/master/doc/README_macos.md)
* [Web](https://github.com/llfbandit/stts/blob/master/doc/README_web.md)
* [Windows](https://github.com/llfbandit/stts/blob/master/doc/README_windows.md)

## Misc. infos / warnings

- Speech recognition is time limited. You can't use it to fill very long texts in a single session.
- Speech recognition will auto stop, when detecting silence.
- This plugin is offline first, this can't be guaranteed.