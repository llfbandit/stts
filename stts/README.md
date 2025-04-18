# stts

Speech-to-Text Flutter plugin.

## Getting Started

## Usage
```dart
import 'package:stts/stts.dart';

final stts = Stts();

// Get state changes
stts.onStateChanged.listen(
  (speechState) {
    // SpeechState.start/stop
  },
  onError: (err) {
    // Retrieve errors from here
  },
);

// Get intermediate and final results.
stts.onResultChanged.listen((result) {
  // The current result String
});

// Start speech recognition.
stts.start();

// ...optionnaly, abort with stts.stop();

// As always, don't forget to release resources.
stts.dispose();
```

## Platforms setup & infos

### Android

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

### iOS

### web

Browsers supporting speech recognition: https://caniuse.com/speech-recognition

- `hasPermision` is redirected to `isSupported`. There's no direct permission to ask but starting recognition.
  - So the permission request will be prompted when calling `start`.

## Misc. infos / warnings

- Speech recognition is time limited. You can't use it to fill very long texts in a single session.
- Where possible, offline recognition is queried.