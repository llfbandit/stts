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
