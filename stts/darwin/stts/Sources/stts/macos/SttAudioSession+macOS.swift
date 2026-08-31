#if os(macOS)
import AVFoundation

// macOS has no audio session, only the microphone permission.
class SttAudioSession {
  func requestRecordPermission(_ result: @escaping (_: Bool) -> Void) {
    AVCaptureDevice.requestAccess(for: .audio, completionHandler: result)
  }

  func activate() throws {}

  func restore() {}

  func reset() {}
}
#endif
