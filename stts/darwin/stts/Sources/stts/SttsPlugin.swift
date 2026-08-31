#if os(iOS)
import Flutter
#else
import FlutterMacOS
#endif

public class SttsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
    let messenger = registrar.messenger()
    #else
    let messenger = registrar.messenger
    #endif

    // STT
    let sttMethodChannel = FlutterMethodChannel(name: "com.llfbandit.stt/methods", binaryMessenger: messenger)

    let sttStateEventChannel = FlutterEventChannel(name: "com.llfbandit.stt/states", binaryMessenger: messenger)
    let sttStateEventHandler = SttStateStreamHandler()
    sttStateEventChannel.setStreamHandler(sttStateEventHandler)

    let sttResultEventChannel = FlutterEventChannel(name: "com.llfbandit.stt/results", binaryMessenger: messenger)
    let sttResultEventHandler = SttResultStreamHandler()
    sttResultEventChannel.setStreamHandler(sttResultEventHandler)
    
    // TTS
    let ttsMethodChannel = FlutterMethodChannel(name: "com.llfbandit.tts/methods", binaryMessenger: messenger)

    let ttsStateEventChannel = FlutterEventChannel(name: "com.llfbandit.tts/states", binaryMessenger: messenger)
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
  
  #if os(iOS)
  public func applicationWillTerminate(_ application: UIApplication) {
    stt.dispose()
    tts.dispose()
  }
  #else
  public func handleWillTerminate(_ notification: Notification) {
    stt.dispose()
    tts.dispose()
  }
  #endif
  
  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    stt.dispose()
    tts.dispose()
  }
}
