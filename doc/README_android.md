# Android

Minimum version: 21.0

## Speech-to-Text

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

- Pause will stop immediately but resume will restart the current utterance below API 26.

## Text-to-Speech

Apps targeting Android 11+ (API level 30) that use text-to-speech should declare in the manifest file:
```xml
<queries>
  <intent>
    <action android:name="android.intent.action.TTS_SERVICE" />
  </intent>
</queries>
```