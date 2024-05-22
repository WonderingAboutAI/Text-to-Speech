# Text-to-Speech

## Text-to-Speech Editor for MacOS

This MacOS desktop application lets you generate an audio scipt using OpenAI's GPT4-Turbo model and record spoken audio using AI voices from OpenAI and ElevvenLabs. Built using SwiftUI and APIs from OpenAI and ElevenLabs, this application provides an intuitive interface for testing a wide variety of AI voices and generating audio content.

### Features

- **Generate Audio Script**: Prompt GPT4-Turbo to create an audio script with or without SSML. **Warning:** Neither OpenAI nor ElevenLabs consistently supports SSML, although sometimes GPT4 will recognize it.
- **Edit and Save Scripts**: Edit scripts and export them as text files. 
- **Try Voices**: Choose from a variety of voices provided by OpenAI and ElevenLabs to find the one that best suits your needs.
- **Playback Audio**: Listen to the generated audio directly within the app, with controls for play, pause, and stop.
- **Save MP# files**: Save audio recordings as MP3s to use in your projects.

### Getting Started

### API keys

To use this app, you will need to get API keys from OpenAI and ElevenLabs.

### OpenAI 

Visit [OpenAI's websiteOpenAI](https://www.openai.com)

Sign up for an account or log in if you already have one.

Navigate to the API key page and follow the instructions to generate a new API key.

For more information, consult [OpenAI's official documentation.](https://platform.openai.com/docs/api-reference)


⚠️ **Please take precautions to keep your API key secure per OpenAI's guidance:**

Remember that your API key is a secret! Do not share it with others or expose it in any client-side code (browsers, apps). Production requests must be routed through your backend server where your API key can be securely loaded from an environment variable or key management service.


### ElevenLabs

Visit [ElevenLabs' website](https://elevenlabs.io)

Sign up for an account or log in if you already have one.

Once logged in, navigate to your profile. You can access your API key by clicking on your profile picture, then selecting "Profile + API key" from the menu.

For more information, consult [OpenAI's official documentation.](https://platform.openai.com/docs/api-reference)

On the profile page, click on the eye icon to reveal your xi-api-key. This is the API key you will use to authenticate API requests.

### Package dependencies

Before you can run this application, you'll need to add the following package dependency to your project:

- **SwiftOpenAI**: https://github.com/jamesrochabrun/SwiftOpenAI 

This package defines functions for accessing GPT4-Turbo and the Whisper TTS model through OpenAI's API

Logic for the **ElevenLabs API** is built into the app itself and was adapted from this iOS package: https://swiftpackageindex.com/ArchieGoodwin/ElevenlabsSwift

**Do not add this dependency**, it does not support MacOS.


### Installation
Clone the repository: <https://github.com/KarenSpinner/Text-to-Speech>

Open your project in Xcode.

Add the **SwiftOpenAI package dependency** mentioned above through Xcode’s Swift Package Manager integration.

Initialize the **OpenAI service** using your API key. You can do this from ContentView.swift:

```
let apiKey = openAI // Replace with your actual API key
service = OpenAIServiceFactory.service(apiKey: apiKey)
```

Initialize the **ElevenLabs service** using your API key. You can do this from Edit and Record_ElevenLabs.swift:

```
public class ElevenlabsSwift {
    private var elevenLabsAPI: String
    
    public required init(elevenLabsAPI: String) {
        self.elevenLabsAPI = elevenLabsAPI
    }
 ```

Run the application through Xcode. Once started, the main interface allows you to:

- Generate and edit a voiceover script.
- Select OpenAI and ElevenLabs voices.
- Generate the speech to hear the playback.
- Play, pause, and stop generated audio.
- Save the generated audio as an MP3 file.

### License

Distributed under the MIT License. See LICENSE for more information.
