# web

## Speech-to-Text

Browsers supporting speech recognition: https://caniuse.com/speech-recognition

- `hasPermision` is redirected to `isSupported`. There's no direct permission to ask but starting recognition.
  - So the permission request will be prompted when calling `start`.