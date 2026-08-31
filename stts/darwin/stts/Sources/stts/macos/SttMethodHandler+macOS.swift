#if os(macOS)
import FlutterMacOS

extension SttMethodHandler {
  func handlePlatform(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }
}
#endif
