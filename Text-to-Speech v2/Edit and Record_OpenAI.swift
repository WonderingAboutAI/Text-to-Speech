import SwiftUI
import AVFoundation
import SwiftOpenAI

struct ScriptEditorView: View {
    @Binding var script: String
    @State private var lastProcessedScript: String? = nil
    @State private var lastSelectedVoice: AudioSpeechParameters.Voice? = nil // To track the last selected voice
    @State private var audioData: Data?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isProcessing = false
    var service: OpenAIService
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedVoice: AudioSpeechParameters.Voice = .shimmer // Default voice
    @State private var isPlaying = false

    var body: some View {
        VStack {
            Text("Choose voice:")
                .font(.headline)
                .padding()

            Picker("Voice", selection: $selectedVoice) {
                Text("Alloy").tag(AudioSpeechParameters.Voice.alloy)
                Text("Echo").tag(AudioSpeechParameters.Voice.echo)
                Text("Fable").tag(AudioSpeechParameters.Voice.fable)
                Text("Onyx").tag(AudioSpeechParameters.Voice.onyx)
                Text("Nova").tag(AudioSpeechParameters.Voice.nova)
                Text("Shimmer").tag(AudioSpeechParameters.Voice.shimmer)
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            .background(Color.blue.opacity(0.1)) // You can change the color as you like
            .cornerRadius(10)
            
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

//Play and pause button
            Button(action: {
                if isPlaying {
                    audioPlayer?.pause()
                    isPlaying = false
                } else {
                    Task {
                        if audioPlayer == nil || audioPlayer?.isPlaying == false {
                            await processAudioAndPlay()
                        }
                        isPlaying = true
                        audioPlayer?.play()
                    }
                }
            }) {
                Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
            }
            .buttonStyle(CustomButtonStyle(backgroundColor: isPlaying ? .gray : .green))


                                Button(action: {
                                    audioPlayer?.stop()
                                    audioPlayer?.currentTime = 0
                                }) {
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
            
            Button(action: {
                saveScriptAsText()
            }) {
                Label("Save Script", systemImage: "doc")
            }
            .buttonStyle(CustomButtonStyle(backgroundColor: .blue))
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
            let ttsParameters = AudioSpeechParameters(model: .tts1, input: script, voice: selectedVoice)
            let audioObject = try await service.createSpeech(parameters: ttsParameters)
            self.audioData = audioObject.output
        } catch {
            print("Error generating audio: \(error.localizedDescription)")
        }
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


    private func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
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
