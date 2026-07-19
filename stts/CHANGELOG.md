## 1.3.4
* fix(android): Don't mute ringer on devices without vibrator.
* fix(android): Ignore TTS resume when not paused.
* fix(android): Stop STT and restore ringer mode when recognition becomes unavailable.
* fix(android): Track TTS resume position per utterance.
* fix(android): Normalize language tags (e.g. en_US, en-us).
* fix(android): Report download model end when on device recognition is unavailable.
* fix(android): Retrieve STT languages only once during initialization.
* fix: Queue all calls, including isSupported and platform specific ones.
* fix(android): Guard TTS init against concurrent dispose.
* fix(android): Run speech recognizer callbacks on main thread.
* fix(android): Mutate TTS utterance data on main thread only.
* fix(android): Restore ringer mode on quick stop/start cycle.
* fix(Android): Disable offline mode when no language is retrieved.
* fix(windows): Initialize TTS option values.
* fix(windows): Escape TTS text as XML.
* fix(windows): Release audio input token on STT start.
* fix(windows): Select first matching voice on language change.
* fix(windows): Keep STT recognition context alive until dispose.
* fix(windows): Return empty list when TTS voices cannot be enumerated.
* fix(windows): Encode SAPI strings as UTF-8.
* fix(windows): Release SAPI interfaces on error paths.
* fix(windows): Allow STT restart right after stop.

## 1.3.3
* fix(ios): allowBluetooth deprecation.
* fix(darwin): Properly propagate SttError errors.
* fix(darwin): Dissociate state check vs. listener check.
* fix(darwin): TO now provides final result.
* fix(darwin): Remove now useless tiny timer on iOS when stopping with fix applied in 1.3.2.

## 1.3.2
* fix(darwin): prevent tap reinstall crash on rapid start/stop.

## 1.3.1
* fix(Android): replace force-unwrap of TTS start arguments with callOrError.
* fix(android): Prevent missed TtsState.Stop.
* fix(Android): Potential NPE.
* fix(Windows): Pointer release issues.
* fix(darwin): transcription.segments[0] without empty check crashes on empty segments.
* fix(darwin): Don't Apple's main-thread requirement for AVSpeechSynthesizer.

## 1.3.0
* chore: Updates minimum supported SDK version to Flutter 3.44/Dart 3.12.
* Android:
    * chore: Move to AGP 9.x.
    * chore: Move to Kotlin Gradle DSL.
* iOS:
    * chore: Completes Swift Package Manager integration.
* macOS:
    * chore: Completes Swift Package Manager integration.

## 1.2.6
* fix(Android): Check if on device recognition is available before creating.

## 1.2.5
* fix(Android/STT): Improve compatibility with older APIs/devices and offline mode.
* chore(Android): compileSdk 36 / kotlin 2.2.

## 1.2.4
* fix(Android/STT): Offline/online behaviour consistency (and truncated detection).

## 1.2.3
* fix(iOS/macOS/TTS): Event firing regression.

## 1.2.2
* fix(iOS/macOS/TTS): Event firing regression.

## 1.2.1
* fix(iOS/macOS/TTS): Event firing regression.

## 1.2.0
* feat(STT): Allow online usage.
* fix(iOS/macOS): compilation issue under some circumstances.
* fix(iOS/macOS/TTS): Event firing when stressing the plugin.
* fix(iOS/macOS/TTS): Stay away from UI thread.

## 1.1.2
* fix(iOS/macOS/TTS): Event firing when stressing the plugin.

## 1.1.1
* fix(iOS/macOS/TTS): Event firing when stressing the plugin.

## 1.1.0
* feat(TTS): Add queue flush option.
* feat(TTS): Add pre/post silence delay option.
* fix(Android/STT): Increase delay by 100ms for `muteSystemSounds`. Ends of sounds were sometimes hearable.

## 1.0.2
* fix(iOS/macOS/STT): Properly initialize default language.

## 1.0.1
* fix(Android/TTS): Double implicit cast error.
* fix(iOS/TTS): Crash when setting voice.
* fix(macOS/TTS): Crash when setting voice.

## 1.0.0
* feat(iOS/STT): Add audio session management.
* fix(Windows): Throw `PlatformException` on error.
* fix(Android/STT): Code cleanup with some improvement.
* fix(iOS/macOS): Small code fixes/improvements.

## 0.9.1
* feat(Android/STT): Add `muteSystemSounds` to mute default system beep sounds.
* feat(STT): Add recognition options.

## 0.9.0
* Supports all platforms but linux.
* Beta stage.
