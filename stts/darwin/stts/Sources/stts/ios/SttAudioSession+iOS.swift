#if os(iOS)
import AVFAudio

class SttAudioSession {
  // When true, recognition sets up the session and restores it on stop.
  var manage = true
  private var saved: (category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions)?

  func requestRecordPermission(_ result: @escaping (_: Bool) -> Void) {
    AVAudioSession.sharedInstance().requestRecordPermission(result)
  }

  func activate() throws {
    guard manage else { return }

    let session = AVAudioSession.sharedInstance()
    saved = (session.category, session.mode, session.categoryOptions)

    #if compiler(<6.2)
    try setCategory(.playAndRecord, options: [.duckOthers, .defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
    #else
    try setCategory(.playAndRecord, options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
    #endif
    try setActive(true)
  }

  func restore() {
    guard let saved else { return }
    self.saved = nil

    let session = AVAudioSession.sharedInstance()
    // Let other apps restore their volume. Restore the category after, so it doesn't interrupt them.
    try? session.setActive(false, options: .notifyOthersOnDeactivation)
    try? session.setCategory(saved.category, mode: saved.mode, options: saved.options)
  }

  func reset() {
    manage = true
  }

  func setActive(_ active: Bool) throws {
    try AVAudioSession.sharedInstance().setActive(active)
  }

  func setCategory(_ category: AVAudioSession.Category, options: AVAudioSession.CategoryOptions) throws {
    try AVAudioSession.sharedInstance().setCategory(category, options: options)
  }
}
#endif
