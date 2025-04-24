import Flutter

public class SttsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let sttMethodChannel = FlutterMethodChannel(name: "com.llfbandit.stt/methods", binaryMessenger: registrar.messenger())

    let sttStateEventChannel = FlutterEventChannel(name: "com.llfbandit.stt/states", binaryMessenger: registrar.messenger())
    let sttStateEventHandler = SttStateStreamHandler()
    sttStateEventChannel.setStreamHandler(sttStateEventHandler)

    let sttResultEventChannel = FlutterEventChannel(name: "com.llfbandit.stt/results", binaryMessenger: registrar.messenger())
    let sttResultEventHandler = SttResultStreamHandler()
    sttResultEventChannel.setStreamHandler(sttResultEventHandler)

    let instance = SttsPlugin(stateEventHandler: sttStateEventHandler, resultEventHandler: sttResultEventHandler)

    sttMethodChannel.setMethodCallHandler(SttMethodHandler(instance.stt).handle)

    registrar.addApplicationDelegate(instance)
  }

  private let stt: Stt
  
  init(stateEventHandler: SttStateStreamHandler, resultEventHandler: SttResultStreamHandler) {
    stt = Stt(stateEventHandler: stateEventHandler, resultEventHandler: resultEventHandler)
  }
  
  public func applicationWillTerminate(_ application: UIApplication) {
    stt.dispose()
  }
  
  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    stt.dispose()
  }
}
