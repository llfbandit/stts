# Integration tests

Live tests of the plugin on a real device, simulator or browser. They use the
platform engines, so results depend on the device (voices, recognizer, network).

- `tts_test.dart`: speaking, queue modes, pause/resume, stop, dispose.
- `stt_test.dart`: recognition lifecycle only (no speech is spoken to the microphone).

Tests skip themselves when the feature is unavailable on the device
(no TTS voice, no recognizer, permission not granted).
Tests marked Android use native helpers from the example app (`MainActivity.kt`).

Run commands from `stts/example`.

## Android

The microphone permission can't be granted from a test. `flutter test` uninstalls the app
after each run by default, so keep it installed and grant the permission once:

```sh
flutter test integration_test -d <device-id> --no-uninstall
adb shell pm grant com.llfbandit.stts_example android.permission.RECORD_AUDIO
flutter test integration_test -d <device-id> --no-uninstall
```

Skipped tests print their reason (`Skipped: ...`), as `flutter test` doesn't report it.
Some checks read native state through the example app, like audio still playing after Stop.

Ringer mode tests change the ringer between normal and vibrate. They skip when Do Not Disturb is on, or when the device has no vibrator.

## iOS / macOS

```sh
flutter test integration_test -d <simulator-id|macos>
```

Microphone and speech recognition must be allowed once for the example app
(iOS Simulator: `xcrun simctl privacy booted grant microphone com.llfbandit.sttsExample`,
then allow speech recognition in the app or Settings).

## Windows

```sh
flutter test integration_test/tts_test.dart -d windows
flutter test integration_test/stt_test.dart -d windows
```

Run each test file separately: the second app launch of a multi-file run fails to connect.

Speech recognition must be enabled in Settings > Privacy & security > Speech.

## Web

Web tests run through `flutter drive` and need a WebDriver on port 4444
([chromedriver](https://googlechromelabs.github.io/chrome-for-testing/) or
[msedgedriver](https://developer.microsoft.com/microsoft-edge/tools/webdriver/)):

```sh
chromedriver --port=4444
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/tts_test.dart -d chrome
```

Run each test file separately. Browsers may block speech without a user gesture.
