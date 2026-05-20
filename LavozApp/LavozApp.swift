import SwiftUI
import AVFoundation

@main
struct LavozApp: App {
    @StateObject private var auth = AuthService.shared
    
    init() {
        setupAudio()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
        }
    }
    
    private func setupAudio() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }
}
