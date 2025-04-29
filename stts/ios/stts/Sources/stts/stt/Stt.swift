import Speech

enum SttError: Error {
  case error(_ message: String)
}

enum SttState: Int {
  case stop = 0
  case start = 1
}

class Stt {
  private var currentLocale: Locale = Locale.current
  
  private let audioEngine = AVAudioEngine()
  private var recognizer: SFSpeechRecognizer?
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  
  private var stateEventHandler: SttStateStreamHandler
  private var resultEventHandler: SttResultStreamHandler
  
  init(stateEventHandler: SttStateStreamHandler, resultEventHandler: SttResultStreamHandler) {
    self.stateEventHandler = stateEventHandler
    self.resultEventHandler = resultEventHandler
  }
  
  func isSupported() -> Bool {
    return true
  }
  
  func getLanguage() -> String {
    return currentLocale.identifier
  }
  
  func setLanguage(_ language: String) {
    if let language = getLanguages().first(where: { $0 == language }) {
      currentLocale = Locale(identifier: language)
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
  
  func start() throws {
    stop()

    try prepareRecognition()
    
    audioEngine.prepare()
    try audioEngine.start()
    
    stateEventHandler.sendEvent(SttState.start)
  }
  
  func stop() {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    
    recognitionRequest?.endAudio()
    recognitionRequest = nil
    
    recognitionTask?.finish()
    recognitionTask = nil
    
    recognizer = nil
    
    stateEventHandler.sendEvent(SttState.stop)
  }
  
  func dispose() {
    stop()
  }

  private func prepareRecognition() throws {
    let recognizer = SFSpeechRecognizer(locale: currentLocale)
    guard let recognizer else {
      throw SttError.error("Failed to create recognizer.")
    }

    // setup request
    let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

    recognitionRequest.shouldReportPartialResults = true

    if #available(iOS 13, *) {
      if recognizer.supportsOnDeviceRecognition {
        recognitionRequest.requiresOnDeviceRecognition = true
      }
    }
    
    // setup task
    let recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
      guard let self = self else { return }

      var isFinal = false
      
      if let result = result {
        let transcription = result.bestTranscription

        if !transcription.formattedString.isEmpty {
          self.resultEventHandler.sendEvent(transcription.formattedString)
        }
        
        // isFinal seems to be always false, stops with confidence instead.
        // Partial results are always with confidence == 0.
        let confidence = transcription.segments[0].confidence
        isFinal = result.isFinal || confidence > 0.0 ? true : false
      } else if let error = error {
        self.stateEventHandler.sendErrorEvent(error)
      }

      if error != nil || isFinal {
        self.stop()
      }
    }

    // setup audio
    let audioSession = AVAudioSession.sharedInstance()
    
    try audioSession.setCategory(.playAndRecord,
                                 options: [.duckOthers, .defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    
    let inputNode = audioEngine.inputNode
    let format = inputNode.inputFormat(forBus: 0)
    
    // feed our recognition task with request
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, when) in
      recognitionRequest.append(buffer)
    }
    
    self.recognitionRequest = recognitionRequest
    self.recognitionTask = recognitionTask
    self.recognizer = recognizer
  }
}
