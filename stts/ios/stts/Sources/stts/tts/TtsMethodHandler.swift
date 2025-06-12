import Flutter

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
      let args = call.arguments as! [String: Any]
      let text = args["text"] as! String
      let mode = args["mode"] as! String

      tts.start(text, mode: TtsQueueMode(rawValue: mode)!)
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
      let args = call.arguments as! [String: Any]
      let language = args["language"] as! String
      
      tts.setLanguage(language)
      result(nil)

    case "getLanguages":
      result(tts.getLanguages())
      
    case "setVoice":
      let args = call.arguments as! [String: Any]
      let voice = args["voiceId"] as! String
      
      tts.setVoice(voice)
      result(nil)
      
    case "getVoices":
      result(tts.getVoices())
      
    case "getVoicesByLanguage":
      let args = call.arguments as! [String: Any]
      let language = args["language"] as! String
      
      result(tts.getVoicesByLanguage(language))
      
    case "setPitch":
      let args = call.arguments as! [String: Any]
      let pitch = args["pitch"] as! NSNumber
      
      tts.setPitch(pitch.floatValue)
      result(nil)
      
    case "setRate":
      let args = call.arguments as! [String: Any]
      let rate = args["rate"] as! NSNumber
      
      tts.setRate(rate.floatValue)
      result(nil)
      
    case "setVolume":
      let args = call.arguments as! [String: Any]
      let volume = args["volume"] as! NSNumber
      
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
