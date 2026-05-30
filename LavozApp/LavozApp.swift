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
          let root = scene.windows.first?.rootViewController else { return }

    let playerVC = AVPlayerViewController()
    playerVC.player = player
    playerVC.showsPlaybackControls = true
    playerVC.videoGravity = .resizeAspect
    playerVC.updatesNowPlayingInfoCenter = false
    playerVC.delegate = FullscreenDelegate.shared

    let container = FullscreenContainerVC()
    container.addChild(playerVC)
    container.view.addSubview(playerVC.view)
    playerVC.view.frame = container.view.bounds
    playerVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    playerVC.didMove(toParent: container)

    container.modalPresentationStyle = .fullScreen
    root.present(container, animated: true)
}

private class FullscreenContainerVC: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }
    override var shouldAutorotate: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIDevice.current.setValue(UIDeviceOrientation.landscapeLeft.rawValue, forKey: "orientation")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
    }
}

private class FullscreenDelegate: NSObject, AVPlayerViewControllerDelegate {
    static let shared = FullscreenDelegate()

    func playerViewControllerDidDismiss(_ playerViewController: AVPlayerViewController) {
        UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
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
