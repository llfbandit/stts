import Flutter

public class SttsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // STT
    let sttMethodChannel = FlutterMethodChannel(name: "com.llfbandit.stt/methods", binaryMessenger: registrar.messenger())

    let sttStateEventChannel = FlutterEventChannel(name: "com.llfbandit.stt/states", binaryMessenger: registrar.messenger())
    let sttStateEventHandler = SttStateStreamHandler()
    sttStateEventChannel.setStreamHandler(sttStateEventHandler)

    let sttResultEventChannel = FlutterEventChannel(name: "com.llfbandit.stt/results", binaryMessenger: registrar.messenger())
    let sttResultEventHandler = SttResultStreamHandler()
    sttResultEventChannel.setStreamHandler(sttResultEventHandler)
    
    // TTS
    let ttsMethodChannel = FlutterMethodChannel(name: "com.llfbandit.tts/methods", binaryMessenger: registrar.messenger())

    let ttsStateEventChannel = FlutterEventChannel(name: "com.llfbandit.tts/states", binaryMessenger: registrar.messenger())
    let ttsStateEventHandler = TtsStateStreamHandler()
    ttsStateEventChannel.setStreamHandler(ttsStateEventHandler)
    
    let instance = SttsPlugin(
      sttStateEventHandler: sttStateEventHandler,
      sttResultEventHandler: sttResultEventHandler,
      ttsStateEventHandler: ttsStateEventHandler
    )

    sttMethodChannel.setMethodCallHandler(SttMethodHandler(instance.stt).handle)
    ttsMethodChannel.setMethodCallHandler(TtsMethodHandler(instance.tts).handle)

    registrar.addApplicationDelegate(instance)
  }

  private let stt: Stt
  private let tts: Tts
  
  init(sttStateEventHandler: SttStateStreamHandler,
       sttResultEventHandler: SttResultStreamHandler,
       ttsStateEventHandler: TtsStateStreamHandler) {
    stt = Stt(stateEventHandler: sttStateEventHandler, resultEventHandler: sttResultEventHandler)
    tts = Tts(ttsStateEventHandler)
  }
  
  public func applicationWillTerminate(_ application: UIApplication) {
    stt.dispose()
    tts.dispose()
  }
  
  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    stt.dispose()
    tts.dispose()
  }
}
