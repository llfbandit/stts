#if os(iOS)
import Flutter
#else
import FlutterMacOS
#endif

class TtsMethodHandler {
  private let tts: Tts

  init(_ tts: Tts) {
    self.tts = tts
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(tts.isSupported())

    case "start":
      guard let text: String = call.arg("text") else {
        return result(FlutterError.invalidArg("tts", "text"))
      }
      guard let mode: String = call.arg("mode"), let queueMode = TtsQueueMode(rawValue: mode) else {
        return result(FlutterError.invalidArg("tts", "mode"))
      }

      let options = TtsOptions(
        queueMode: queueMode,
        preSilenceMs: call.arg("preSilence"),
        postSilenceMs: call.arg("postSilence")
      )

      tts.start(text, options: options)
      result(nil)

    case "stop":
      tts.stop()
      result(nil)

    case "pause":
      tts.pause()
      result(nil)

    case "resume":
      tts.resume()
      result(nil)

    case "getLanguage":
      result(tts.getLanguage())

    case "setLanguage":
      guard let language: String = call.arg("language") else {
        return result(FlutterError.invalidArg("tts", "language"))
      }

      tts.setLanguage(language)
      result(nil)

    case "getLanguages":
      result(tts.getLanguages())

    case "setVoice":
      guard let voice: String = call.arg("voiceId") else {
        return result(FlutterError.invalidArg("tts", "voiceId"))
      }

      tts.setVoice(voice)
      result(nil)

    case "getVoices":
      result(tts.getVoices())

    case "getVoicesByLanguage":
      guard let language: String = call.arg("language") else {
        return result(FlutterError.invalidArg("tts", "language"))
      }

      result(tts.getVoicesByLanguage(language))

    case "setPitch":
      guard let pitch: NSNumber = call.arg("pitch") else {
        return result(FlutterError.invalidArg("tts", "pitch"))
      }

      tts.setPitch(pitch.floatValue)
      result(nil)

    case "setRate":
      guard let rate: NSNumber = call.arg("rate") else {
        return result(FlutterError.invalidArg("tts", "rate"))
      }

      tts.setRate(rate.floatValue)
      result(nil)

    case "setVolume":
      guard let volume: NSNumber = call.arg("volume") else {
        return result(FlutterError.invalidArg("tts", "volume"))
      }

      tts.setVolume(volume.floatValue)
      result(nil)

    case "dispose":
      tts.dispose()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
