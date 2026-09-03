#if os(iOS)
import Flutter
#else
import FlutterMacOS
#endif

class SttMethodHandler {
  let stt: Stt

  init(_ stt: Stt) {
    self.stt = stt
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(stt.isSupported())
      
    case "hasPermission":
      stt.hasPermission { granted in
        DispatchQueue.main.async {
          result(granted)
        }
      }
      
    case "getLanguage":
      result(stt.getLanguage())
      
    case "setLanguage":
      guard let language: String = call.arg("language") else {
        return result(FlutterError.invalidArg("stt", "language"))
      }

      stt.setLanguage(language)
      result(nil)
      
    case "getLanguages":
      result(stt.getLanguages())
      
    case "start":
      guard let options: [String: Any] = call.arg("options") else {
        return result(FlutterError.invalidArg("stt", "options"))
      }

      do {
        try stt.start(SttRecognitionOptions.fromMap(options))
        result(nil)
      } catch {
        result(FlutterError(code: "stt", message: error.localizedDescription, details: nil))
      }
      
    case "stop":
      stt.stop()
      result(nil)
      
    case "dispose":
      stt.dispose()
      result(nil)
      
    default:
      handlePlatform(call, result: result)
    }
  }
}
