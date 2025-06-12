import AVFAudio

enum TtsError: Error {
  case error(_ message: String)
}

enum TtsState: Int {
  case stop = 0
  case start = 1
  case pause = 2
}

enum TtsQueueMode: String {
  case flush
  case add
}

extension Comparable {
  func clamp(_ f: Self, _ t: Self) -> Self {
    if self < f { return f }
    if self > t { return t }
    return self
  }
}

class Tts: NSObject, AVSpeechSynthesizerDelegate {
  private let ttsStateEventHandler: TtsStateStreamHandler
  
  private var synthesizer: AVSpeechSynthesizer?
  private var language = AVSpeechSynthesisVoice.currentLanguageCode()
  private var pitch: Float = 1.0 // 0.5 - 2.0
  private var rate: Float = 1.0 // 0.1 - 10.0
  private var volume: Float = 1.0 // 0.0 - 1.0
  private var voiceId: String?
  private var utteranceQueued = 0
  
  init(_ ttsStateEventHandler: TtsStateStreamHandler) {
    self.ttsStateEventHandler = ttsStateEventHandler
    
    super.init()
    
    resetParams()
  }
  
  func isSupported() -> Bool {
    return true
  }
  
  func start(_ text: String, mode: TtsQueueMode) {
    if synthesizer == nil {
      synthesizer = AVSpeechSynthesizer()
      synthesizer?.delegate = self
    }

    if mode == TtsQueueMode.flush {
      synthesizer?.delegate = nil
      stop()
      synthesizer?.delegate = self
    }

    let utterance = AVSpeechUtterance(string: text)
    utterance.pitchMultiplier = pitch
    utterance.rate = rate
    utterance.volume = volume
    
    if let voiceId = voiceId {
      utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId)
    } else {
      utterance.voice = AVSpeechSynthesisVoice(language: language)
    }
    
    DispatchQueue.global(qos: .background).async {
      self.synthesizer?.speak(utterance)
    }
  }
  
  func stop() {
    synthesizer?.stopSpeaking(at: AVSpeechBoundary.immediate)
  }
  
  func pause() {
    synthesizer?.pauseSpeaking(at: AVSpeechBoundary.immediate)
  }
  
  func resume() {
    synthesizer?.continueSpeaking()
  }
  
  func setVolume(_ volume: Float) {
    self.volume = volume.clamp(0.0, 1.0)
  }
  
  func setPitch(_ pitch: Float) {
    self.pitch = pitch.clamp(0.5, 2.0)
  }

  func setRate(_ rate: Float) {
    // speech rate is scaled from 0x to 1x with values [0, 0.5]
    // speech rate is scaled from 1x to 4x with values [0.5, 1.0]
    var adjustedRate: Float
    if rate <= 1 {
      adjustedRate = (rate - 0.1) / (1.0 - 0.1) * 0.5
    } else {
      adjustedRate = (rate - 1.0) / (10.0 - 1.0) * (1.0 - 0.5) + 0.5
    }

    self.rate = adjustedRate.clamp(AVSpeechUtteranceMinimumSpeechRate, AVSpeechUtteranceMaximumSpeechRate)
  }
  
  func setLanguage(_ language: String) {
    if let voice = AVSpeechSynthesisVoice.speechVoices().first(where: {$0.language == language}) {
      self.language = voice.language
    }
  }
  
  func getLanguage() -> String {
    return language
  }
  
  func getLanguages() -> [String] {
    return Array(Set(AVSpeechSynthesisVoice.speechVoices().map { $0.language }))
  }
  
  func setVoice(_ voiceId: String) {
    if let voice = AVSpeechSynthesisVoice.speechVoices().first(where: {$0.identifier == voiceId}) {
      self.voiceId = voice.identifier
    }
  }
  
  func getVoices() -> [[String: Any]] {
    return AVSpeechSynthesisVoice.speechVoices().map { mapVoice($0) }
  }
  
  func getVoicesByLanguage(_ language: String) -> [[String: Any]] {
    return AVSpeechSynthesisVoice.speechVoices()
      .filter({ $0.language == language })
      .map { mapVoice($0) }
  }
  
  func dispose() {
    stop()
    
    synthesizer?.delegate = nil
    synthesizer = nil
    resetParams()
  }
  
  private func resetParams() {
    language = AVSpeechSynthesisVoice.currentLanguageCode()
    pitch = 1.0
    setRate(1.0)
    volume = 1.0
    voiceId = nil
    utteranceQueued = 0
  }
  
  private func mapVoice(_ voice: AVSpeechSynthesisVoice) -> [String: Any] {
    var gender = "unspecified"
    
    switch voice.gender {
    case .male:
      gender = "male"
    case .female:
      gender = "female"
    case .unspecified:
      gender = "unspecified"
    @unknown default:
      gender = "unspecified"
    }
  
    return [
      "id": voice.identifier,
      "language": voice.language,
      "languageInstalled": true,
      "name": voice.name,
      "gender": gender,
      "networkRequired": false,
    ]
  }
  
  // AVSpeechSynthesizerDelegate delegate
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    utteranceQueued += 1
    ttsStateEventHandler.sendEvent(TtsState.start)
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
    ttsStateEventHandler.sendEvent(TtsState.pause)
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
    ttsStateEventHandler.sendEvent(TtsState.start)
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    utteranceQueued -= 1

    // Delay slightly stop because didStart can be triggered after this one
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      if self.utteranceQueued == 0 {
        self.ttsStateEventHandler.sendEvent(TtsState.stop)
      }
    }
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    utteranceQueued = 0
    ttsStateEventHandler.sendEvent(TtsState.stop)
  }
}
