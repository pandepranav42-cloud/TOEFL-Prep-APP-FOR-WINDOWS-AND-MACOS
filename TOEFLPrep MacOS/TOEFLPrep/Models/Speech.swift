import AVFoundation

enum Speech {
    private static let synth = AVSpeechSynthesizer()

    static func say(_ text: String) {
        guard !text.isEmpty else { return }
        synth.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        synth.speak(utterance)
    }
}
