#if os(iOS)
import Flutter
import AVFAudio

extension SttMethodHandler {
  func handlePlatform(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "ios.manageAudioSession":
      guard let manage = call.arguments as? Bool else {
        result(FlutterError(code: "stt", message: "Failed to parse call.arguments from Flutter.", details: nil))
        return
      }
      stt.audioSession.manage = manage
      result(nil)
    
    case "ios.setAudioSessionActive":
      guard let active = call.arguments as? Bool else {
        result(FlutterError(code: "stt", message: "Failed to parse call.arguments from Flutter.", details: nil))
        return
      }
      
      do {
        try stt.audioSession.setActive(active)
        result(nil)
      } catch {
        result(FlutterError(code: "stt", message: error.localizedDescription, details: nil))
      }
      
    case "ios.setAudioSessionCategory":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "stt", message: "Failed to parse call.arguments from Flutter.", details: nil))
        return
      }
      guard let category = args["category"] as? String else  {
        result(FlutterError(code: "stt", message: "Call missing mandatory parameter category.", details: nil))
        return
      }
      guard let options = args["options"] as? [String] else  {
        result(FlutterError(code: "stt", message: "Call missing mandatory parameter options.", details: nil))
        return
      }
      
      do {
        try stt.audioSession.setCategory(toAVCategory(category), options: toAVCategoryOptions(options))
        result(nil)
      } catch {
        result(FlutterError(code: "stt", message: error.localizedDescription, details: nil))
      }
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func toAVCategory(_ category: String) -> AVAudioSession.Category {
    switch category {
    case "ambient": return .ambient
    case "playAndRecord": return .playAndRecord
    case "playback": return .playback
    case "record": return .record
    case "soloAmbient": return .soloAmbient
    default: return .playAndRecord
    }
  }

  private func toAVCategoryOptions(_ options: [String]) -> AVAudioSession.CategoryOptions {
    var result: AVAudioSession.CategoryOptions = []
    
    for option in options {
      switch option {
      case "mixWithOthers": result.insert(.mixWithOthers)
      case "duckOthers": result.insert(.duckOthers)
      case "interruptSpokenAudioAndMixWithOthers": result.insert(.interruptSpokenAudioAndMixWithOthers)
      #if compiler(<6.2)
      case "allowBluetooth": result.insert(.allowBluetooth)
      #else
      case "allowBluetooth": result.insert(.allowBluetoothHFP)
      #endif
      case "allowBluetoothA2DP": result.insert(.allowBluetoothA2DP)
      case "allowAirPlay": result.insert(.allowAirPlay)
      case "defaultToSpeaker": result.insert(.defaultToSpeaker)
      default: break
      }
    }

    return result
  }
}
#endif
