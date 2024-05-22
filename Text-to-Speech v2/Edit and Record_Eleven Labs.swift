import SwiftUI
import AVFoundation

struct ScriptEditorViewAlt: View {
    @Binding var script: String
    @State private var lastProcessedScript: String? = nil
    @State private var lastSelectedVoice: String? = nil
    @State private var audioData: Data?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isProcessing = false
    var service: ElevenlabsSwift
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedVoice: String = "default_voice_id"
    @State private var isPlaying = false
    @State private var voices: [Voice] = []
    @State private var isLoadingVoices = true

    var body: some View {
        VStack {
            Text("Choose voice:")
                .font(.headline)
                .padding()

            if isLoadingVoices {
                ProgressView()
            } else {
                Picker("Voice", selection: $selectedVoice) {
                    ForEach(voices, id: \.voice_id) { voice in
                        Text(voice.name).tag(voice.voice_id)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }

            Text("Edit script:")
                .font(.headline)
                .padding()

            TextEditor(text: $script)
                .padding()
                .cornerRadius(8)
                .frame(minWidth: 800, minHeight: 500, maxHeight: .infinity)

            if isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                controlButtons
            }
        }
        .padding()
        .onAppear {
            loadVoices()
        }
    }

    @ViewBuilder
    var controlButtons: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Label("Done", systemImage: "checkmark")
            }
            .buttonStyle(CustomButtonStyle(backgroundColor: .black.opacity(0.9)))

            Button(action: togglePlayback) {
                Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
            }
            .buttonStyle(CustomButtonStyle(backgroundColor: isPlaying ? .gray : .green))

            Button(action: stopAudio) {
                Label("Stop", systemImage: "stop.fill")
            }
            .buttonStyle(CustomButtonStyle(backgroundColor: .red))

            Button(action: {
                Task {
                    await processAudioAndSave()
                }
            }) {
                Label("Save MP3", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(CustomButtonStyle(backgroundColor: .blue))
            .disabled(isProcessing)

            Button(action: saveScriptAsText) {
                Label("Save Script", systemImage: "doc")
            }
            .buttonStyle(CustomButtonStyle(backgroundColor: .blue))
        }
    }

    private func loadVoices() {
        Task {
            do {
                let fetchedVoices = try await service.fetchVoices()
                voices = fetchedVoices
                isLoadingVoices = false
                if let firstVoice = voices.first {
                    selectedVoice = firstVoice.voice_id // Set the default selected voice
                }
            } catch {
                print("Failed to fetch voices: \(error)")
                isLoadingVoices = false
            }
        }
    }

    private func shouldProcessAudio() -> Bool {
        script != lastProcessedScript || selectedVoice != lastSelectedVoice
    }

    private func processAudioAndPlay() async {
        if shouldProcessAudio() {
            await generateAudioData()
        }
        playAudio()
    }

    private func processAudioAndSave() async {
        if shouldProcessAudio() {
            await generateAudioData()
        }
        saveAudio()
    }

    private func generateAudioData() async {
        isProcessing = true
        defer {
            isProcessing = false
            lastProcessedScript = script
            lastSelectedVoice = selectedVoice // Update last selected voice
        }

        do {
            let url = try await service.textToSpeech(voice_id: selectedVoice, text: script)
            let data = try Data(contentsOf: url)
            self.audioData = data
        } catch {
            print("Error generating audio: \(error.localizedDescription)")
        }
    }

    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
        } else {
            Task {
                await processAudioAndPlay()
                isPlaying = true
                audioPlayer?.play()
            }
        }
    }

    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
    }

    
    private func playAudio() {
        guard let audioData = audioData else { return }

        // Check if the audio player needs to be initialized or if the data has changed
        if audioPlayer == nil || audioPlayer?.data != audioData {
            do {
                audioPlayer = try AVAudioPlayer(data: audioData)
            } catch {
                print("Error initializing audio player: \(error.localizedDescription)")
                return
            }
        }

        // Ensure the audio player is not already playing
        guard !(audioPlayer?.isPlaying ?? false) else { return }

        audioPlayer?.play()
        isPlaying = true

        // Use an asynchronous task to wait for the audio to finish playing
        Task {
            await waitForAudioToFinish()
        }
    }

    
    @MainActor
    private func waitForAudioToFinish() async {
        // Use a while loop that periodically checks if the audio is still playing
        while audioPlayer?.isPlaying ?? false {
            try? await Task.sleep(nanoseconds: 100_000_000) // Sleep for 0.1 seconds
        }
        isPlaying = false
    }



    private func saveAudio() {
        guard let audioData = audioData else { return }

        DispatchQueue.main.async {
            let panel = NSSavePanel()
            panel.allowedFileTypes = ["mp3"]
            panel.nameFieldStringValue = "output.mp3"

            panel.begin { response in
                if response == .OK, let url = panel.url {
                    do {
                        try audioData.write(to: url)
                    } catch {
                        print("Error saving audio file: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func saveScriptAsText() {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["txt"]
        panel.nameFieldStringValue = "script.txt"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try script.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Error saving script: \(error.localizedDescription)")
                }
            }
        }
    }
}

