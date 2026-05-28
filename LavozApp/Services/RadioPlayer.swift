import Foundation
import AVKit
import Combine

struct ShowInfo: Identifiable {
    let id: Int
    let time: String
    let end: String
    let title: String
    let desc: String
    let thumbnail: String?
    let isLive: Bool

    var thumbnailURL: URL? {
        let base = "https://j.prioridad.cl/radiolavoz/img/thumbnails/"
        let file = thumbnail ?? "logo.png"
        guard let encoded = file.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        return URL(string: base + encoded)
    }
}

class RadioPlayer: ObservableObject {
    static let shared = RadioPlayer()

    @Published var isPlaying = false
    @Published var isLoading = true
    @Published var hasVideo = false
    @Published var currentTitle = "Cargando…"
    @Published var liveShow: ShowInfo?
    @Published var nextShow: ShowInfo?

    let player: AVPlayer
    private var playerObserver: NSKeyValueObservation?
    private var sizeObserver: NSKeyValueObservation?
    private var refreshTimer: Timer?

    private let streamURL = URL(string: "https://live.mtna.tv/hls/lvp/lvp.m3u8")!
    private let apiBase = "https://j.prioridad.cl/radiolavoz"

    private init() {
        let item = AVPlayerItem(url: streamURL)
        player = AVPlayer(playerItem: item)
        setupPlaybackObserver()
        setupVideoDetection(for: item)
        fetchLiveNow()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.fetchLiveNow()
        }
    }

    private func setupPlaybackObserver() {
        playerObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] p, _ in
            DispatchQueue.main.async {
                self?.isPlaying = p.timeControlStatus == .playing
                if p.timeControlStatus != .waitingToPlayAtSpecifiedRate {
                    self?.isLoading = false
                }
            }
        }
    }

    // Detecta si el stream tiene video real (presentationSize > 0 significa que hay video)
    private func setupVideoDetection(for item: AVPlayerItem) {
        sizeObserver = item.observe(\.presentationSize, options: [.new, .initial]) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.hasVideo = item.presentationSize.width > 0
            }
        }
    }

    func play() { isLoading = true; player.play() }
    func pause() { player.pause() }
    func toggle() { isPlaying ? pause() : play() }

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

    private func fetch(endpoint: String, completion: @escaping ([String: Any]) -> Void) {
        guard let url = URL(string: apiBase + endpoint) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
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
            currentTitle = liveShow!.title
        } else {
            liveShow = nil
            currentTitle = "Música continua"
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
    }

    deinit {
        playerObserver?.invalidate()
        sizeObserver?.invalidate()
        refreshTimer?.invalidate()
    }
}
