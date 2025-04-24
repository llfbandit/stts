import Flutter

class SttMethodHandler {
  private let stt: Stt

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
      
    case "getLocale":
      result(stt.getLocale())
      
    case "setLocale":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "stt", message: "Failed to parse call.arguments from Flutter.", details: nil))
        return
      }
      guard let language = args["language"] as? String else  {
        result(FlutterError(code: "stt", message: "Call missing mandatory parameter language.", details: nil))
        return
      }

      stt.setLocale(language)
      result(nil)
      
    case "getSupportedLocales":
      result(stt.getSupportedLocales())
      
    case "start":
      do {
        try stt.start()
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
      result(FlutterMethodNotImplemented)
    }
  }
}