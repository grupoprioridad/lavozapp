import Foundation
import AVKit
import Combine
import UserNotifications
import MediaPlayer

struct ShowInfo: Identifiable {
    let id: Int
    let time: String
    let end: String
    let title: String
    let desc: String
    let thumbnail: String?
    let isLive: Bool

    var thumbnailURL: URL? {
        let base = "https://radiolavoz.cl/img/thumbnails/"
        let file = thumbnail ?? "logo.png"
        guard let encoded = file.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        return URL(string: base + encoded)
    }
}

struct AppExclusiveStream: Decodable {
    let active: Bool
    let type: String?
    let url: String?
    let title: String?
    let description: String?
}

class RadioPlayer: ObservableObject {
    static let shared = RadioPlayer()

    @Published var isPlaying = false
    @Published var isLoading = true
    @Published var hasVideo = false
    @Published var currentTitle = "Cargando…"
    @Published var liveShow: ShowInfo?
    @Published var nextShow: ShowInfo?
    @Published var exclusiveStream: AppExclusiveStream?
    @Published var isExclusiveActive = false
    @Published var isReady = false

    let player: AVPlayer

    private enum StreamMode { case audio, video, exclusive }
    private var currentMode: StreamMode = .audio
    private var radioBossTitle: String? = nil

    // Audio: Icecast MP3 (siempre disponible)
    // Video: HLS (solo cuando hay señal de video)
    private let audioURL = URL(string: "https://live.lavozdepucon.cl:8000/stream.mp3")!
    private let videoURL = URL(string: "https://live.mtna.tv/hls/lvp/primary/index.m3u8")!
    private let apiBase  = "https://radiolavoz.cl"

    // App token para contenido exclusivo — identifica que el request viene de la app nativa
    // El backend debe validar este header en /api/app-stream
    private static var appToken: String {
        let a = "4f8c3b2a"
        let b = "1d9e7f05"
        let c = "6a2b8d3e"
        return "lvp_app_\(a)\(b)\(c)"
    }

    private var playerObserver: NSKeyValueObservation?
    private var sizeObserver: NSKeyValueObservation?
    private var stallObserver: NSKeyValueObservation?
    private var stallTimer: Timer?
    private var healthTimer: Timer?
    private var nowPlayingTimer: Timer?
    private var scheduleTimer: Timer?
    private var exclusiveTimer: Timer?

    private init() {
        player = AVPlayer()

        setupPlaybackObserver()
        setupRemoteControls()
        initialSetup()
    }

    /// Verifica contenido exclusivo primero; si no hay, arranca en modo audio
    private func initialSetup() {
        fetchExclusive(endpoint: "/api/app-stream") { [weak self] json in
            guard let self = self else { return }
            if let data = try? JSONSerialization.data(withJSONObject: json),
               let stream = try? JSONDecoder().decode(AppExclusiveStream.self, from: data),
               stream.active, let url = stream.url, let urlObj = URL(string: url) {
                DispatchQueue.main.async {
                    self.exclusiveStream = stream
                    self.activateExclusiveMode(url: urlObj, title: stream.title, type: stream.type)
                    self.isReady = true
                    self.startTimers()
                }
            } else {
                DispatchQueue.main.async {
                    let item = self.makeItem(url: self.audioURL)
                    self.player.replaceCurrentItem(with: item)
                    self.setupStallRecovery(for: item)
                    self.isReady = true
                    self.startTimers()
                    self.fetchLiveNow()
                    self.fetchNowPlaying()
                    self.checkAndSwitch()
                }
            }
        }
    }

    private func startTimers() {
        healthTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.checkAndSwitch()
        }
        nowPlayingTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.fetchNowPlaying()
        }
        scheduleTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.fetchLiveNow()
        }
        exclusiveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.fetchAppExclusiveStream()
        }
    }

    // MARK: - Playback control

    func play()   { isLoading = true; player.play() }
    func pause()  { player.pause() }
    func toggle() { isPlaying ? pause() : play() }

    // MARK: - Stream switching (replica checkAndSwitch del web)

    private func checkAndSwitch() {
        guard currentMode != .exclusive else { return }
        fetch(endpoint: "/api/stream-health") { [weak self] json in
            let videoAvailable = json["video"] as? Bool ?? false
            DispatchQueue.main.async {
                if videoAvailable {
                    self?.activateVideoMode()
                } else {
                    self?.activateAudioMode()
                }
            }
        }
    }

    private func activateVideoMode() {
        guard currentMode != .video else { return }
        currentMode = .video
        sendLiveNotification()
        let wasPlaying = isPlaying
        sizeObserver?.invalidate()
        stallObserver?.invalidate()
        stallTimer?.invalidate()
        stallTimer = nil
        let item = makeItem(url: videoURL)
        player.replaceCurrentItem(with: item)
        setupVideoDetection(for: item)
        setupStallRecovery(for: item)
        if wasPlaying { player.play() }
    }

    private func activateAudioMode() {
        guard currentMode != .audio else { return }
        currentMode = .audio
        hasVideo = false
        let wasPlaying = isPlaying
        sizeObserver?.invalidate()
        stallObserver?.invalidate()
        stallTimer?.invalidate()
        stallTimer = nil
        let item = makeItem(url: audioURL)
        player.replaceCurrentItem(with: item)
        setupStallRecovery(for: item)
        if wasPlaying { player.play() }
    }

    // MARK: - Exclusive App Stream

    func fetchAppExclusiveStream() {
        fetchExclusive(endpoint: "/api/app-stream") { [weak self] json in
            guard let data = try? JSONSerialization.data(withJSONObject: json),
                  let stream = try? JSONDecoder().decode(AppExclusiveStream.self, from: data) else { return }
            DispatchQueue.main.async {
                self?.exclusiveStream = stream
                if stream.active, let url = stream.url, let urlObj = URL(string: url) {
                    self?.activateExclusiveMode(url: urlObj, title: stream.title, type: stream.type)
                } else if self?.currentMode == .exclusive {
                    self?.deactivateExclusiveMode()
                }
            }
        }
    }

    private func activateExclusiveMode(url: URL, title: String?, type: String?) {
        guard currentMode != .exclusive else { return }
        currentMode = .exclusive
        isExclusiveActive = true
        sizeObserver?.invalidate()
        stallObserver?.invalidate()
        stallTimer?.invalidate()
        stallTimer = nil
        let item = makeItem(url: url)
        player.replaceCurrentItem(with: item)
        if type == "video" {
            setupVideoDetection(for: item)
        } else {
            hasVideo = false
        }
        setupStallRecovery(for: item)
        if let t = title, !t.isEmpty { currentTitle = t }
        updateNowPlaying()
        isLoading = true
        player.play()
    }

    private func deactivateExclusiveMode() {
        currentMode = .audio
        isExclusiveActive = false
        hasVideo = false
        sizeObserver?.invalidate()
        stallObserver?.invalidate()
        stallTimer?.invalidate()
        stallTimer = nil
        let item = makeItem(url: audioURL)
        player.replaceCurrentItem(with: item)
        setupStallRecovery(for: item)
        if isPlaying { player.play() }
    }

    // MARK: - Notificación de video en vivo

    private func sendLiveNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Radio La Voz de Pucón"
        content.body  = "Hay contenido en vivo en La Voz de Pucón"
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "lvp-live-video",
            content: content,
            trigger: nil  // entrega inmediata
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Item factory

    private func makeItem(url: URL) -> AVPlayerItem {
        let item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = 15
        return item
    }

    // MARK: - Stall recovery

    private func setupStallRecovery(for item: AVPlayerItem) {
        var hasPlayedSuccessfully = false
        stallObserver = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if item.isPlaybackLikelyToKeepUp {
                    hasPlayedSuccessfully = true
                    self.stallTimer?.invalidate()
                    self.stallTimer = nil
                } else if hasPlayedSuccessfully,
                          self.player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                    guard self.stallTimer == nil else { return }
                    self.stallTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { [weak self] _ in
                        self?.reconnectCurrentStream()
                    }
                }
            }
        }
    }

    private func reconnectCurrentStream() {
        stallTimer = nil
        guard player.timeControlStatus == .waitingToPlayAtSpecifiedRate,
              let url = (player.currentItem?.asset as? AVURLAsset)?.url else { return }
        stallObserver?.invalidate()
        let item = makeItem(url: url)
        player.replaceCurrentItem(with: item)
        setupStallRecovery(for: item)
        player.play()
    }

    // MARK: - Video detection

    private func setupVideoDetection(for item: AVPlayerItem) {
        sizeObserver = item.observe(\.presentationSize, options: [.new, .initial]) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.hasVideo = item.presentationSize.width > 0
            }
        }
    }

    // MARK: - Playback observer

    private func setupPlaybackObserver() {
        playerObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] p, _ in
            DispatchQueue.main.async {
                self?.isPlaying = p.timeControlStatus == .playing
                if p.timeControlStatus != .waitingToPlayAtSpecifiedRate {
                    self?.isLoading = false
                }
                self?.updateNowPlaying()
            }
        }
    }

    // MARK: - API: Now Playing (RadioBoss via Icecast)

    private func fetchNowPlaying() {
        guard !isExclusiveActive else { return }
        fetchExclusive(endpoint: "/api/now-playing") { [weak self] json in
            let title = json["title"] as? String
            DispatchQueue.main.async {
                self?.radioBossTitle = title
                if let t = title, !t.isEmpty {
                    self?.currentTitle = t
                    self?.updateNowPlaying()
                }
            }
        }
    }

    // MARK: - API: Schedule (programación)

    func fetchLiveNow() {
        fetch(endpoint: "/api/schedule") { [weak self] json in
            DispatchQueue.main.async { self?.parseLiveShow(json: json) }
        }
    }

    func fetchSchedule(day: String, completion: @escaping ([ShowInfo]) -> Void) {
        fetch(endpoint: "/api/schedule?day=\(day)") { json in
            let raw = json["shows"] as? [[String: Any]] ?? []
            let parsed = raw.map { s in
                ShowInfo(
                    id: s["id"] as? Int ?? 0,
                    time: s["time"] as? String ?? "",
                    end: s["end"] as? String ?? "",
                    title: s["title"] as? String ?? "",
                    desc: s["desc"] as? String ?? "",
                    thumbnail: s["thumbnail"] as? String,
                    isLive: s["isLive"] as? Bool ?? false
                )
            }
            DispatchQueue.main.async { completion(parsed) }
        }
    }

    // MARK: - Private helpers

    private func fetch(endpoint: String, completion: @escaping ([String: Any]) -> Void) {
        guard let url = URL(string: apiBase + endpoint) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let d = data,
                  let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else { return }
            completion(json)
        }.resume()
    }

    private func fetchExclusive(endpoint: String, completion: @escaping ([String: Any]) -> Void) {
        guard let url = URL(string: apiBase + endpoint) else { return }
        var req = URLRequest(url: url)
        req.setValue(Self.appToken, forHTTPHeaderField: "X-App-Token")
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let d = data,
                  let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else { return }
            completion(json)
        }.resume()
    }

    private func parseLiveShow(json: [String: Any]) {
        if let live = json["liveNow"] as? [String: Any] {
            liveShow = ShowInfo(
                id: live["id"] as? Int ?? 0,
                time: live["time"] as? String ?? "",
                end: live["end"] as? String ?? "",
                title: live["title"] as? String ?? "En vivo",
                desc: live["desc"] as? String ?? "",
                thumbnail: live["thumbnail"] as? String,
                isLive: true
            )
        } else {
            liveShow = nil
        }

        if let next = json["nextShow"] as? [String: Any] {
            nextShow = ShowInfo(
                id: next["id"] as? Int ?? 0,
                time: next["time"] as? String ?? "",
                end: next["end"] as? String ?? "",
                title: next["title"] as? String ?? "",
                desc: next["desc"] as? String ?? "",
                thumbnail: next["thumbnail"] as? String,
                isLive: false
            )
        } else {
            nextShow = nil
        }

        // RadioBoss tiene prioridad; si no hay, usar título del programa
        if radioBossTitle == nil {
            currentTitle = liveShow?.title ?? "Música continua"
        }
        updateNowPlaying()
    }

    // MARK: - Lock screen / Control Center

    private func setupRemoteControls() {
        let cmd = MPRemoteCommandCenter.shared()

        cmd.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        cmd.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        cmd.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.toggle()
            return .success
        }
        // La radio en vivo no tiene avance/retroceso
        cmd.skipForwardCommand.isEnabled  = false
        cmd.skipBackwardCommand.isEnabled = false
        cmd.nextTrackCommand.isEnabled    = false
        cmd.previousTrackCommand.isEnabled = false
    }

    func updateNowPlaying() {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle:            currentTitle,
            MPMediaItemPropertyArtist:           "Radio La Voz de Pucón",
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        // Artwork: logo de la radio
        if let image = UIImage(named: "logo-radio") {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    deinit {
        playerObserver?.invalidate()
        sizeObserver?.invalidate()
        stallObserver?.invalidate()
        stallTimer?.invalidate()
        healthTimer?.invalidate()
        nowPlayingTimer?.invalidate()
        scheduleTimer?.invalidate()
        exclusiveTimer?.invalidate()
    }
}
