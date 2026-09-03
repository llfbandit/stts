#if os(iOS)
import Flutter
#else
import FlutterMacOS
#endif

extension FlutterMethodCall {
  func arg<T>(_ name: String) -> T? {
    return (arguments as? [String: Any])?[name] as? T
  }
}

extension FlutterError {
  static func invalidArg(_ code: String, _ name: String) -> FlutterError {
    return FlutterError(code: code, message: "Missing or invalid parameter \(name).", details: nil)
  }
}
