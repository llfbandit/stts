import Flutter

class TtsStateStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  var currentState = TtsState.stop
  
  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink) -> FlutterError? {
      
      self.eventSink = events
      return nil
    }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
  
  func sendEvent(_ state: TtsState) {
    guard currentState != state else { return }
      
    currentState = state
    
    if let eventSink = eventSink {
      DispatchQueue.main.async {
        eventSink(state.rawValue)
      }
    }
  }
  
  func sendErrorEvent(_ error: Error) {
    if let eventSink = eventSink {
      DispatchQueue.main.async {
        eventSink(FlutterError(code: "tts", message: error.localizedDescription, details: nil))
      }
    }
  }
}