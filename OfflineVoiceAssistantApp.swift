//
//  OfflineVoiceAssistantApp.swift
//  OfflineVoiceAssistant
//
//  Created by OpenAI on 2025.
//

import SwiftUI
import Speech
import AVFoundation

class VoiceAssistant: NSObject, SFSpeechRecognizerDelegate, ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    @Published var transcript = "Say something..."
    @Published var response = ""

    override init() {
        super.init()
        speechRecognizer?.delegate = self
    }

    func startListening() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                DispatchQueue.main.async {
                    try? self.startSession()
                }
            default:
                DispatchQueue.main.async {
                    self.transcript = "Speech recognition not authorized."
                }
            }
        }
    }

    private func startSession() throws {
        if audioEngine.isRunning {
            stopListening()
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        let inputNode = audioEngine.inputNode
        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.transcript = result.bestTranscription.formattedString
                self.handleCommand(command: self.transcript.lowercased())
            }

            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        transcript = "Listening..."
    }

    func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        transcript = "Stopped listening."
    }

    private func handleCommand(command: String) {
        if command.contains("time") {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            response = "The time is \(formatter.string(from: Date()))."
        } else if command.contains("date") {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            response = "Today is \(formatter.string(from: Date()))."
        } else if command.contains("hello") {
            response = "Hello! How can I assist you offline?"
        } else {
            response = "Sorry, I didn't understand that."
        }
    }
}

struct ContentView: View {
    @ObservedObject var assistant = VoiceAssistant()

    var body: some View {
        VStack(spacing: 20) {
            Text("🗣️ Offline Voice Assistant")
                .font(.title)
                .bold()

            Text(assistant.transcript)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            Text(assistant.response)
                .foregroundColor(.blue)
                .padding()

            HStack {
                Button("Start Listening") {
                    assistant.startListening()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Stop") {
                    assistant.stopListening()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
    }
}

@main
struct OfflineVoiceAssistantApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
