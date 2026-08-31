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

class TtsOptions {
  let queueMode: TtsQueueMode
  let preSilenceMs: Int?
  let postSilenceMs: Int?

  init(queueMode: TtsQueueMode = TtsQueueMode.add,
       preSilenceMs: Int? = nil,
       postSilenceMs: Int? = nil
  ) {
    self.queueMode = queueMode
    self.preSilenceMs = preSilenceMs
    self.postSilenceMs = postSilenceMs
  }
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
  private var queuedUtterances = [AVSpeechUtterance]()
  
  init(_ ttsStateEventHandler: TtsStateStreamHandler) {
    self.ttsStateEventHandler = ttsStateEventHandler
    
    super.init()
    
    resetParams()
  }
  
  func isSupported() -> Bool {
    return true
  }
  
  func start(_ text: String, options: TtsOptions) {
    if synthesizer == nil {
      synthesizer = AVSpeechSynthesizer()
      
      #if os(iOS)
      if #available(iOS 13.0, *) {
        synthesizer?.usesApplicationAudioSession = false
      }
      #endif

      synthesizer?.delegate = self
    }

    if options.queueMode == TtsQueueMode.flush && ttsStateEventHandler.currentState != .stop {
      queuedUtterances.removeAll()

      synthesizer?.stopSpeaking(at: AVSpeechBoundary.immediate)
    }

    let utterance = AVSpeechUtterance(string: text)
    utterance.pitchMultiplier = pitch
    utterance.rate = rate
    utterance.volume = volume

    if let silenceMs = options.preSilenceMs {
      utterance.preUtteranceDelay = Double(silenceMs) / 1000.0
    }
    if let silenceMs = options.postSilenceMs {
      utterance.postUtteranceDelay = Double(silenceMs) / 1000.0
    }
    
    if let voiceId = voiceId {
      utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId)
    } else {
      utterance.voice = AVSpeechSynthesisVoice(language: language)
    }

    queuedUtterances.append(utterance)

    synthesizer?.speak(utterance)
    synthesizer?.continueSpeaking()
    ttsStateEventHandler.sendEvent(TtsState.start)
  }
  
  func stop() {
    queuedUtterances.removeAll()

    synthesizer?.stopSpeaking(at: AVSpeechBoundary.immediate)
    ttsStateEventHandler.sendEvent(TtsState.stop)

    synthesizer?.delegate = nil
    synthesizer = nil
  }
  
  func pause() {
    guard let synth = synthesizer else {
      return
    }

    if synth.isSpeaking && !synth.isPaused {
      synth.pauseSpeaking(at: AVSpeechBoundary.immediate)
      ttsStateEventHandler.sendEvent(TtsState.pause)
    }
  }

  func resume() {
    guard let synth = synthesizer else {
      return
    }

    if synth.isSpeaking && synth.isPaused {
      synth.continueSpeaking()
      ttsStateEventHandler.sendEvent(TtsState.start)
    }
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
    if let voice = AVSpeechSynthesisVoice.speechVoices().first(where: { isSameLanguageTag($0.language, language) }) {
      self.language = voice.language

      // Drop a voice of another language, the system then picks the default voice of this one.
      if let voiceId, AVSpeechSynthesisVoice(identifier: voiceId)?.language != voice.language {
        self.voiceId = nil
      }
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
      self.language = voice.language
    }
  }
  
  func getVoices() -> [[String: Any]] {
    return AVSpeechSynthesisVoice.speechVoices().map { mapVoice($0) }
  }
  
  func getVoicesByLanguage(_ language: String) -> [[String: Any]] {
    return AVSpeechSynthesisVoice.speechVoices()
      .filter({ isSameLanguageTag($0.language, language) })
      .map { mapVoice($0) }
  }
  
  func dispose() {
    stop()

    resetParams()
  }
  
  private func resetParams() {
    language = AVSpeechSynthesisVoice.currentLanguageCode()
    pitch = 1.0
    setRate(1.0)
    volume = 1.0
    voiceId = nil
    queuedUtterances.removeAll()
    ttsStateEventHandler.currentState = .stop
  }
  
  private func mapVoice(_ voice: AVSpeechSynthesisVoice) -> [String: Any] {
    var gender = "unspecified"
    
    if #available(iOS 13.0, *) {
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
    }
  
    return [
      "id": voice.identifier,
      "language": voice.language,
      "languageInstalled": true,
      "name": voice.name,
      "gender": gender,
      "networkRequired": false
    ]
  }
  
  // AVSpeechSynthesizerDelegate delegate
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
    ttsStateEventHandler.sendEvent(TtsState.pause)
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
    ttsStateEventHandler.sendEvent(TtsState.start)
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    // Ignore utterances flushed or stopped since, their events can still arrive.
    if !queuedUtterances.contains(where: { $0 === utterance }) { return }

    // Delay slightly stop because this event is fired too soon!
    let defaultShift = 0.2

    // Delay stop because of postUtteranceDelay not taken into account
    Timer.scheduledTimer(withTimeInterval: defaultShift + utterance.postUtteranceDelay, repeats: false) { [weak self] _ in
      self?.dequeue(utterance)
    }
  }

  // Cancelled by the system, stop() and flush already removed their utterances.
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    dequeue(utterance)
  }

  private func dequeue(_ utterance: AVSpeechUtterance) {
    guard let index = queuedUtterances.firstIndex(where: { $0 === utterance }) else { return }

    queuedUtterances.remove(at: index)

    if queuedUtterances.isEmpty {
      ttsStateEventHandler.sendEvent(TtsState.stop)
    }
  }
}
