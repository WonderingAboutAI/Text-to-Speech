import SwiftUI
import AVFoundation
import SwiftOpenAI

struct ContentView: View {
    @State private var userPrompt = "Write a script for a voiceover about the impact of climate change"
    @State private var aiGeneratedContent = "AI-generated text will appear here."
    @State private var includeDisclaimer = false
    @State private var aiDisclaimer = "Please start the script with this statement: This recording was produced by AI."
    @State private var useSSML = false
    @State private var includeAudioDirection = false
    @State private var isProcessing = false
    @State private var showEditor = false
    @State private var showAltEditor = false
    @State private var wordCountDouble: Double = 250  // Using Double for the Slider
    
    let service: OpenAIService
    
    init() {
        let apiKey = openAI // Replace with your actual API key
        service = OpenAIServiceFactory.service(apiKey: apiKey)
    }
    
    var wordCount: Int {
        Int(wordCountDouble)  // Convert Double to Int for word count
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Enter your prompt:")
                .font(.headline)
            
            TextField("", text: $userPrompt)
                .padding()
                .cornerRadius(8)
                .frame(height: 50)  // Set height for the prompt field
            
            Toggle("Include AI Disclaimer", isOn: $includeDisclaimer)
            if includeDisclaimer {
                TextField("AI Disclaimer", text: $aiDisclaimer)
                    .padding()
                    .cornerRadius(8)
                    .frame(height: 50)
            }
            
            Toggle("Use SSML for audio direction", isOn: $useSSML)
            Toggle("Include AI-generated audio direction", isOn: $includeAudioDirection)
            
            VStack(alignment: .leading) {
                Text("Word Count: \(wordCount)")
                Slider(value: $wordCountDouble, in: 10...500, step: 1)
            }
            .padding(.vertical)
            
            TextEditor(text: $aiGeneratedContent)
                .padding()
                .cornerRadius(8)
                .frame(minHeight: 300)
            
            if isProcessing {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
            } else {
                HStack {
                    Spacer()
                    Button("Generate Script") {
                        Task {
                            await generateScript()
                        }
                    }
                    .buttonStyle(CustomButtonStyle(backgroundColor: .blue))
                    
                    Button("Record with OpenAI") {
                        showEditor = true
                    }
                    .buttonStyle(CustomButtonStyle(backgroundColor: .green))
                    .disabled(aiGeneratedContent.isEmpty || aiGeneratedContent == "AI-generated text will appear here.")
                    Button("Record with Eleven Labs") {
                        showAltEditor = true
                    }
                    .buttonStyle(CustomButtonStyle(backgroundColor: .green))
                    .disabled(aiGeneratedContent.isEmpty || aiGeneratedContent == "AI-generated text will appear here.")
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            ScriptEditorView(script: $aiGeneratedContent, service: service)
        }
        
        .sheet(isPresented: $showAltEditor) {
            ScriptEditorViewAlt(script: $aiGeneratedContent, service: ElevenlabsSwift(elevenLabsAPI: elevenLabs))
        }
        .padding()
    }
    
    private func generateScript() async {
        isProcessing = true
        defer { isProcessing = false }
        
        // Construct the full prompt including the disclaimer if needed
        var fullPrompt = userPrompt
        if includeAudioDirection {
            fullPrompt = " Include audio direction." + fullPrompt + "\(wordCount) words total."
        }
        if useSSML {
            fullPrompt = " Use SSML for audio direction." + fullPrompt + "\(wordCount) words total."
        }
        
        // Ensure the disclaimer is added at the very beginning of the script
        if includeDisclaimer {
            fullPrompt = "\(aiDisclaimer) " + fullPrompt + "\(wordCount) words total."
        }
        
        else { fullPrompt += "\(wordCount) words total."}
        
        do {
            let parameters = ChatCompletionParameters(messages: [.init(role: .user, content: .text(fullPrompt))], model: .gpt4)
            let completion = try await service.startChat(parameters: parameters)
            if let firstChoice = completion.choices.first {
                self.aiGeneratedContent = firstChoice.message.content ?? "Error: Could not generate content."
            }
        } catch {
            aiGeneratedContent = "Error: \(error.localizedDescription)"
        }
    }
}


#Preview {
    ContentView()
}

