import Flutter

class StateStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var currentState = SpeechState.stop
  
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
  
  func sendEvent(_ state: SpeechState) {
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
        eventSink(FlutterError(code: "stts", message: error.localizedDescription, details: nil))
      }
    }
  }
}

class ResultStreamHandler: NSObject, FlutterStreamHandler {
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
  
  func sendEvent(_ result: String) {
    if let eventSink = eventSink {
      DispatchQueue.main.async {
        eventSink(result)
      }
    }
  }
}

