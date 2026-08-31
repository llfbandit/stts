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
      guard let text: String = arg(call, "text") else {
        return invalidArg(result, "text")
      }
      guard let mode: String = arg(call, "mode"), let queueMode = TtsQueueMode(rawValue: mode) else {
        return invalidArg(result, "mode")
      }

      let options = TtsOptions(
        queueMode: queueMode,
        preSilenceMs: arg(call, "preSilence"),
        postSilenceMs: arg(call, "postSilence")
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
      guard let language: String = arg(call, "language") else {
        return invalidArg(result, "language")
      }

      tts.setLanguage(language)
      result(nil)

    case "getLanguages":
      result(tts.getLanguages())

    case "setVoice":
      guard let voice: String = arg(call, "voiceId") else {
        return invalidArg(result, "voiceId")
      }

      tts.setVoice(voice)
      result(nil)

    case "getVoices":
      result(tts.getVoices())

    case "getVoicesByLanguage":
      guard let language: String = arg(call, "language") else {
        return invalidArg(result, "language")
      }

      result(tts.getVoicesByLanguage(language))

    case "setPitch":
      guard let pitch: NSNumber = arg(call, "pitch") else {
        return invalidArg(result, "pitch")
      }

      tts.setPitch(pitch.floatValue)
      result(nil)

    case "setRate":
      guard let rate: NSNumber = arg(call, "rate") else {
        return invalidArg(result, "rate")
      }

      tts.setRate(rate.floatValue)
      result(nil)

    case "setVolume":
      guard let volume: NSNumber = arg(call, "volume") else {
        return invalidArg(result, "volume")
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

  private func arg<T>(_ call: FlutterMethodCall, _ name: String) -> T? {
    return (call.arguments as? [String: Any])?[name] as? T
  }

  private func invalidArg(_ result: FlutterResult, _ name: String) {
    result(FlutterError(code: "tts", message: "Missing or invalid parameter \(name).", details: nil))
  }
}
