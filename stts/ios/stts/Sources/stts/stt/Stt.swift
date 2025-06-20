import Speech

enum SttError: Error {
  case error(_ message: String)
}

enum SttState: Int {
  case stop = 0
  case start = 1
}

class SttRecognitionOptions {
  let punctuation: Bool
  let contextualStrings: [String]
  let taskHint: SFSpeechRecognitionTaskHint?
  let offline: Bool
  
  init(punctuation: Bool, contextualStrings: [String], taskHint: SFSpeechRecognitionTaskHint?, offline: Bool) {
    self.punctuation = punctuation
    self.contextualStrings = contextualStrings
    self.taskHint = taskHint
    self.offline = offline
  }
  
  static func fromMap(_ map: [String: Any]) -> SttRecognitionOptions {
    let punctuation = map["punctuation"] as? Bool ?? false
    let contextualStrings = map["contextualStrings"] as? [String] ?? []
    let offline = map["offline"] as? Bool ?? true
    
    var taskHint: SFSpeechRecognitionTaskHint?
    if let iosOptions = map["ios"] as? [String : Any] {
      let taskHintString = iosOptions["taskHint"] as? String
      
      switch taskHintString {
      case "confirmation": taskHint = .confirmation
      case "dictation": taskHint = .dictation
      case "search": taskHint = .search
      default: taskHint = nil
      }
    }
    
    return SttRecognitionOptions(
      punctuation: punctuation,
      contextualStrings: contextualStrings,
      taskHint: taskHint,
      offline: offline
    )
  }
}

class Stt {
  private var currentLanguage = Locale.preferredLanguages[0]
  
  private let audioEngine = AVAudioEngine()
  private var recognizer: SFSpeechRecognizer?
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private var stopTimer: Timer?
  
  private var stateEventHandler: SttStateStreamHandler
  private var resultEventHandler: SttResultStreamHandler
  
  private var manageAudioSession = true
  
  init(stateEventHandler: SttStateStreamHandler, resultEventHandler: SttResultStreamHandler) {
    self.stateEventHandler = stateEventHandler
    self.resultEventHandler = resultEventHandler
  }
  
  func isSupported() -> Bool {
    return true
  }
  
  func getLanguage() -> String {
    return currentLanguage
  }
  
  func setLanguage(_ language: String) {
    if let language = getLanguages().first(where: { $0 == language }) {
      currentLanguage = language
    }
  }
  
  func getLanguages() -> [String] {
    var locales = [String]()
    
    let supportedLocales = SFSpeechRecognizer.supportedLocales()
    for locale in supportedLocales {
      locales.append(locale.identifier)
    }
    
    return locales
  }
  
  func hasPermission(_ result: @escaping (_: Bool) -> Void) {
    SFSpeechRecognizer.requestAuthorization({ status in
      if status == SFSpeechRecognizerAuthorizationStatus.authorized {
        AVAudioSession.sharedInstance().requestRecordPermission({ granted in
          result(granted)
        })
      } else {
        result(false)
      }
    })
  }
  
  func start(_ options: SttRecognitionOptions) throws {
    try prepareRecognition(options)
    
    audioEngine.prepare()
    try audioEngine.start()
    
    stateEventHandler.sendEvent(SttState.start)
  }
  
  func stop() {
    stopTimer?.invalidate()

    let wasInitialized = recognitionRequest != nil
    
    recognitionRequest?.endAudio()
    recognitionRequest = nil
    
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    
    recognitionTask?.cancel()
    recognitionTask = nil
    
    recognizer = nil
    
    // Delay stop event to fix "No speech detected" - 1110 error.
    // In case of restart just after stop.
    if wasInitialized {
      DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: {
        self.stateEventHandler.sendEvent(SttState.stop)
      })
    }
  }
  
  func manageAudioSession(_ manage: Bool) {
    manageAudioSession = manage
  }
  
  func setAudioSessionActive(_ active: Bool) throws {
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setActive(active)
  }
  
  func setAudioSessionCategory(_ category: AVAudioSession.Category, options: AVAudioSession.CategoryOptions) throws {
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(category, options: options)
  }
  
  func dispose() {
    stop()
    
    manageAudioSession = true
  }

  private func prepareRecognition(_ options: SttRecognitionOptions) throws {
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: currentLanguage))
    guard let recognizer else {
      throw SttError.error("Failed to create recognizer.")
    }
    guard recognizer.isAvailable else {
      throw SttError.error("Recognizer is not available.")
    }

    // setup request
    let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

    recognitionRequest.shouldReportPartialResults = true

    if #available(iOS 13, *) {
      if options.offline && recognizer.supportsOnDeviceRecognition {
        recognitionRequest.requiresOnDeviceRecognition = true
      }
    }

    if let taskHint = options.taskHint {
      recognitionRequest.taskHint = taskHint
    }
    if !options.contextualStrings.isEmpty {
      recognitionRequest.contextualStrings = options.contextualStrings
    }
    if #available(iOS 16, *) {
      recognitionRequest.addsPunctuation = options.punctuation
    }
    
    // setup task
    let recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
      guard let self = self else { return }

      if let result = result {
        let transcription = result.bestTranscription

        // isFinal seems to be always false, stops with confidence instead.
        // Partial results are always with confidence == 0.
        let confidence = transcription.segments[0].confidence
        let isFinal = result.isFinal || confidence > 0.0 ? true : false

        if !transcription.formattedString.isEmpty {
          self.resultEventHandler.sendEvent(transcription.formattedString, isFinal)
        }
        if isFinal {
          self.stop()
        } else if #available(iOS 13, *) {
          if !recognitionRequest.requiresOnDeviceRecognition {
            self.stopTimer?.invalidate()
            self.stopTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] timer in
              self?.stop()
            }
          }
        }
      } else if self.recognitionTask != nil, let error = error { // check task to not fire error event on stop/cancel
        self.stateEventHandler.sendErrorEvent(error)
        self.stop()
      }
    }
    
    self.recognitionRequest = recognitionRequest
    self.recognitionTask = recognitionTask
    self.recognizer = recognizer

    // setup audio
    if manageAudioSession {
      try setAudioSessionCategory(.playAndRecord, options: [.duckOthers, .defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
      try setAudioSessionActive(true)
    }
    
    let inputNode = audioEngine.inputNode
    let format = inputNode.inputFormat(forBus: 0)
    
    // feed our recognition task with request
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] (buffer, when) in
      guard let self = self else { return }

      self.recognitionRequest?.append(buffer)
    }
  }
}
