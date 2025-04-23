import Flutter

public class SttsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "stts", binaryMessenger: registrar.messenger())
    
    let stateEventChannel = FlutterEventChannel(name: "com.llfbandit.stts/states", binaryMessenger: registrar.messenger())
    let stateEventHandler = StateStreamHandler()
    stateEventChannel.setStreamHandler(stateEventHandler)
    
    let resultEventChannel = FlutterEventChannel(name: "com.llfbandit.stts/results", binaryMessenger: registrar.messenger())
    let resultEventHandler = ResultStreamHandler()
    resultEventChannel.setStreamHandler(resultEventHandler)
    
    let instance = SttsPlugin(stateEventHandler: stateEventHandler, resultEventHandler: resultEventHandler)
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
  }
  
  private let stts: Stts
  
  init(stateEventHandler: StateStreamHandler, resultEventHandler: ResultStreamHandler) {
    stts = Stts(stateEventHandler: stateEventHandler, resultEventHandler: resultEventHandler)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(stts.isSupported())
      
    case "hasPermission":
      stts.hasPermission { granted in
        DispatchQueue.main.async {
          result(granted)
        }
      }
      
    case "getLocale":
      result(stts.getLocale())
      
    case "setLocale":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "stts", message: "Failed to parse call.arguments from Flutter.", details: nil))
        return
      }
      guard let language = args["language"] as? String else  {
        result(FlutterError(code: "stts", message: "Call missing mandatory parameter language.", details: nil))
        return
      }

      stts.setLocale(language)
      result(nil)
      
    case "getSupportedLocales":
      result(stts.getSupportedLocales())
      
    case "start":
      do {
        try stts.start()
        result(nil)
      } catch {
        result(FlutterError(code: "stts", message: error.localizedDescription, details: nil))
      }
      
    case "stop":
      stts.stop()
      result(nil)
      
    case "dispose":
      stts.dispose()
      result(nil)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  public func applicationWillTerminate(_ application: UIApplication) {
    stts.dispose()
  }
  
  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    stts.dispose()
  }
}
