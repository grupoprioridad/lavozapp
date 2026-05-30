import SwiftUI
import AVKit
import UserNotifications
import OneSignalFramework

private class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    // Muestra la notificación aunque la app esté en primer plano
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

// MARK: - Present fullscreen video with rotation support

func presentFullscreenVideo(_ player: AVPlayer) {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let root = scene.windows.first?.rootViewController,
          root.presentedViewController == nil else { return }

    // Crear un AVPlayer independiente para fullscreen para evitar conflictos
    // con el AVPlayerViewController inline que usa el mismo reproductor
    let currentURL = (player.currentItem?.asset as? AVURLAsset)?.url
        ?? URL(string: "https://live.lavozdepucon.cl:8000/stream.mp3")!
    let fullscreenPlayer = AVPlayer(url: currentURL)
    fullscreenPlayer.play()

    let playerVC = AVPlayerViewController()
    playerVC.player = fullscreenPlayer
    playerVC.showsPlaybackControls = true
    playerVC.videoGravity = .resizeAspect
    playerVC.updatesNowPlayingInfoCenter = false
    playerVC.delegate = FullscreenDelegate.shared

    root.present(playerVC, animated: true)
}

private class FullscreenDelegate: NSObject, AVPlayerViewControllerDelegate {
    static let shared = FullscreenDelegate()

    func playerViewControllerDidDismiss(_ playerViewController: AVPlayerViewController) {
        playerViewController.player?.pause()
    }
}

@main
struct LavozApp: App {
    @StateObject private var auth = AuthService.shared

    private static let notificationDelegate = NotificationDelegate()

    init() {
        setupAudio()
        setupNotifications()
        setupNavBarAppearance()
        OneSignal.initialize("8fda1981-467e-4533-b85a-ba8d8e63057f", withLaunchOptions: nil)
        OneSignal.Notifications.requestPermission({ _ in }, fallbackToSettings: true)
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

    private func setupNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1)]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(red: 0.80, green: 0.08, blue: 0.08, alpha: 1)
    }

    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = Self.notificationDelegate
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
