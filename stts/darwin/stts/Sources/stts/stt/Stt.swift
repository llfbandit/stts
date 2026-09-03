import Speech

enum SttError: LocalizedError {
  case error(_ message: String)

  var errorDescription: String? {
    switch self {
    case .error(let message): return message
    }
  }
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
    #if os(iOS)
    let platformOptions = map["ios"] as? [String : Any]
    #else
    let platformOptions = map["macos"] as? [String : Any]
    #endif

    if let platformOptions {
      let taskHintString = platformOptions["taskHint"] as? String
      
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
  private lazy var currentLanguage = defaultLanguage()
  
  private let audioEngine = AVAudioEngine()
  private var recognizer: SFSpeechRecognizer?
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private var stopTimer: Timer?
  private var partialResult: String?
  
  private var stateEventHandler: SttStateStreamHandler
  private var resultEventHandler: SttResultStreamHandler
  
  let audioSession = SttAudioSession()
  
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
    if let language = getLanguages().first(where: { isSameLanguageTag($0, language) }) {
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
        self.audioSession.requestRecordPermission(result)
      } else {
        result(false)
      }
    })
  }
  
  func start(_ options: SttRecognitionOptions) throws {
    if recognitionTask != nil {
      if audioEngine.isRunning { return }
      // The engine stopped without us (e.g. phone call), end this session before a new one.
      stop()
    }

    do {
      try prepareRecognition(options)

      audioEngine.prepare()
      try audioEngine.start()
    } catch {
      release()
      throw error
    }

    stateEventHandler.sendEvent(SttState.start)
  }

  func stop() {
    // Send the last partial result as final, the cancelled task won't do it.
    if let partialResult, !partialResult.isEmpty {
      resultEventHandler.sendEvent(partialResult, true)
    }

    release()

    stateEventHandler.sendEvent(SttState.stop)
  }

  private func release() {
    // Nothing is set up before the task. Reading inputNode would also open the microphone.
    guard recognitionTask != nil else { return }

    stopTimer?.invalidate()
    partialResult = nil
    
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)

    recognitionRequest?.endAudio()
    recognitionRequest = nil

    recognitionTask?.cancel()
    recognitionTask = nil
    
    recognizer = nil

    audioSession.restore()
  }
  
  func dispose() {
    stop()
    
    audioSession.reset()
  }

  // Preferred languages may have no recognizer (e.g. en-FR, zh-Hant-TW).
  // Falls back to the same language, in the preferred region first (zh-TW), then in the most common one (en-US).
  // Without any match (e.g. cy-GB), uses en-US or the first supported language.
  private func defaultLanguage() -> String {
    let supported = getLanguages().sorted()

    for preferred in Locale.preferredLanguages {
      if let match = supported.first(where: { isSameLanguageTag($0, preferred) }) { return match }

      let locale = Locale(identifier: preferred)
      guard let code = locale.languageCode else { continue }

      let sameLanguage = supported.filter { Locale(identifier: $0).languageCode == code }
      for region in [locale.regionCode] + likelyRegions(code, locale.scriptCode) {
        if let match = sameLanguage.first(where: { Locale(identifier: $0).regionCode == region }) { return match }
      }
      if let match = sameLanguage.first { return match }
    }

    return supported.first(where: { $0 == "en-US" }) ?? supported.first ?? "en-US"
  }

  private func likelyRegions(_ code: String, _ script: String?) -> [String] {
    if #available(iOS 16, macOS 13, *) {
      let language = [code, script].compactMap { $0 }.joined(separator: "-")
      let likely = Locale.Language(identifier: language).maximalIdentifier
      if let region = Locale.Language(identifier: likely).region?.identifier { return [region] }
    }
    // Guess without likely subtags (fr-FR, de-DE, en-US).
    return [code.uppercased(), "US"]
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

    if options.offline && recognizer.supportsOnDeviceRecognition {
      recognitionRequest.requiresOnDeviceRecognition = true
    }

    if let taskHint = options.taskHint {
      recognitionRequest.taskHint = taskHint
    }
    if !options.contextualStrings.isEmpty {
      recognitionRequest.contextualStrings = options.contextualStrings
    }
    if #available(iOS 16, macOS 13, *) {
      recognitionRequest.addsPunctuation = options.punctuation
    }
    
    // setup task
    var recognitionTask: SFSpeechRecognitionTask?
    recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
      guard let self = self, self.recognitionTask === recognitionTask else { return }

      if let result = result {
        let transcription = result.bestTranscription

        // isFinal seems to be always false, stops with confidence instead.
        // Partial results are always with confidence == 0.
        let confidence = transcription.segments.first?.confidence ?? 0.0
        let isFinal = result.isFinal || confidence > 0.0

        if !transcription.formattedString.isEmpty {
          self.resultEventHandler.sendEvent(transcription.formattedString, isFinal)
        }
        if isFinal {
          self.partialResult = nil
        } else if !transcription.formattedString.isEmpty {
          self.partialResult = transcription.formattedString
        }

        if isFinal {
          self.stop()
        } else if !recognitionRequest.requiresOnDeviceRecognition {
          self.stopTimer?.invalidate()
          self.stopTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] timer in
            self?.stop()
          }
        }
      } else if let error = error {
        // Don't let stop() send the partial result as final after an error.
        self.partialResult = nil
        self.stateEventHandler.sendErrorEvent(error)
        self.stop()
      }
    }

    self.recognitionRequest = recognitionRequest
    self.recognitionTask = recognitionTask
    self.recognizer = recognizer

    // setup audio
    try audioSession.activate()
    
    let inputNode = audioEngine.inputNode
    let format = inputNode.inputFormat(forBus: 0)

    // installTap raises an exception that Swift can't catch on this format (e.g. no input route, playback only category).
    guard format.sampleRate > 0 && format.channelCount > 0 else {
      throw SttError.error("Audio input is not available.")
    }

    // Remove any stale tap before installing — avoids crash when start() is called
    // while a previous tap removal is still in-flight on the recognition callback queue.
    inputNode.removeTap(onBus: 0)

    // Feed the local request, the tap runs on the audio thread while stop() clears the property.
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, when) in
      recognitionRequest.append(buffer)
    }
  }
}
