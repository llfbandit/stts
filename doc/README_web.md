# web

## Speech-to-Text

Browsers supporting speech recognition: https://caniuse.com/speech-recognition

- `hasPermision` is redirected to `isSupported`. There's no direct permission to ask but starting recognition.
  - So the permission request will be prompted when calling `start`.

- `getLanguages` will likely return an empty collection as there's no API to retrieve supported languages.
- `setLanguage` may fallback to default language dialect if not supported... But the property is still set...