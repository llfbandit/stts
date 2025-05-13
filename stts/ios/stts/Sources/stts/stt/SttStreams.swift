import Flutter

class SttStateStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var currentState = SttState.stop
  
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
  
  func sendEvent(_ state: SttState) {
    if let eventSink = eventSink, currentState != state {
      currentState = state
      
      DispatchQueue.main.async {
        eventSink(state.rawValue)
      }
    }
  }
  
  func sendErrorEvent(_ error: Error) {
    if let eventSink = eventSink {
      DispatchQueue.main.async {
        eventSink(FlutterError(code: "stt", message: error.localizedDescription, details: nil))
      }
    }
  }
}

class SttResultStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  
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
  
  func sendEvent(_ result: String, _ isFinal: Bool) {
    if let eventSink = eventSink {
      DispatchQueue.main.async {
        eventSink(["text": result, "isFinal": isFinal])
      }
    }
  }
}

