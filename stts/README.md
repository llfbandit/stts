# stts

Speech-to-Text and Text-to-Speech Flutter plugin.

No dependency. All implementations use what the platform provides.

## Platform Speech-to-Text parity matrix
| Feature             | Android       | iOS          | macOS           | web     
|---------------------|---------------|--------------|---------------|---------
| permission          | ✔️            |   ✔️        | ✔️          | ✔️     
| language selection  | ✔️            |   ✔️        |  ✔️         |  ✔️    

## Platform Text-to-Speech parity matrix
| Feature             | Android       | iOS          | macOS           | web     
|---------------------|---------------|--------------|---------------|---------
| pause/resume        | ✔️            |   ✔️        | ✔️          | ✔️     
| language selection  | ✔️            |   ✔️        |  ✔️         |  ✔️    
| voice selection     | ✔️            |   ✔️        |  ✔️         |  ✔️    
| pitch               | ✔️            |   ✔️        |  ✔️         |  ✔️    
| rate                | ✔️            |  ✔️         |  ✔️         |  ✔️    
| volume              | ✔️           | ✔️           | ✔️          | ✔️     

## Usage of Speech-to-Text
```dart
import 'package:stts/stts.dart';

final stt = Stt();

// Get state changes
final sub = stt.onStateChanged.listen(
  (speechState) {
    // SpeechState.start/stop
  },
  onError: (err) {
    // Retrieve listener errors from here
  },
);

// Get intermediate and final results.
stt.onResultChanged.listen((result) {
  // The current result String
});

// Start speech recognition.
stt.start();

// ...optionnaly, abort with stt.stop();

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
  (ttsState) {
    // TtsState.start/stop/pause
  },
  onError: (err) {
    // Retrieve listener errors from here
  },
);

// Add utterance. Texts are queued.
await tts.start('Hello');
await tts.start('world!');

// ...optionnaly, abort with tts.stop();

// As always, don't forget to release resources.
sub.cancel();
tts.dispose();
```

## Platforms setup & infos

You can either use one or both engines in your app. So permissions are only required for dedicated engine.

### Android

Minimum version: 21.0

#### Speech-to-Text

Update AndroidManifest.xml file:

Put all directives under manifest chapter.
```xml
<!-- Required to access microphone -->
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<!-- Required because speech recognition service may access internet -->
<uses-permission android:name="android.permission.INTERNET" />
```

For apps targeting Android 11+ (API level 30), interaction with a speech recognition service requires element to be added to the manifest file:
```xml
<queries>
  <intent>
    <action android:name="android.speech.RecognitionService" />
  </intent>
</queries>
```

- Sounds are emitted by the system. There's nothing the plugin can do about it.
- Pause will stop immediately but resume will restart the current utterance below API 26.

#### Text-to-Speech

Apps targeting Android 11+ (API level 30) that use text-to-speech should declare in the manifest file:
```xml
<queries>
  <intent>
    <action android:name="android.intent.action.TTS_SERVICE" />
  </intent>
</queries>
```

### iOS

Minimum version: 12.0

#### Speech-to-Text

Permissions to set in `ios/Runner/Info.plist`:
```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>Allow speech recognition for speech-to-text feature</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need to access to the microphone for speech-to-text feature</string>
```

### macOS

Minimum version: 10.15

#### Speech-to-Text

Permissions to set in `macos/Runner/Info.plist`:
```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>Allow speech recognition for speech-to-text feature</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need to access to the microphone for speech-to-text feature</string>
```

In capabilities, activate "Audio input" in debug AND release schemes, or directly via xml *.entitlements:
```xml
<key>com.apple.security.device.audio-input</key>
<true/>
```

- When running through VSCode, the app will crash when requesting speech recognition permission. Using XCode is the only known workaround for now.

### web

#### Speech-to-Text

Browsers supporting speech recognition: https://caniuse.com/speech-recognition

- `hasPermision` is redirected to `isSupported`. There's no direct permission to ask but starting recognition.
  - So the permission request will be prompted when calling `start`.

## Misc. infos / warnings

- Speech recognition is time limited. You can't use it to fill very long texts in a single session.
- Where possible, offline recognition is queried.