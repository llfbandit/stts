# macOS

Minimum version: 10.15

## Speech-to-Text

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