import Foundation
import AVKit
import Combine

class RadioPlayer: ObservableObject {
    static let shared = RadioPlayer()
    
    @Published var isPlaying = false
    @Published var isLoading = true
    @Published var currentTitle = "Cargando…"
    
    let player: AVPlayer
    private var playerObserver: NSKeyValueObservation?
    private let streamURL = URL(string: "https://live.mtna.tv/hls/lvp/lvp.m3u8")!
    
    private init() {
        let asset = AVAsset(url: streamURL)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        setupObservers()
        loadSchedule()
    }
    
    private func setupObservers() {
        playerObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] p, _ in
            DispatchQueue.main.async {
                self?.isPlaying = p.timeControlStatus == .playing
                if p.timeControlStatus != .waitingToPlayAtSpecifiedRate {
                    self?.isLoading = false
                }
            }
        }
    }
    
    func play() {
        isLoading = true
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    func toggle() {
        isPlaying ? pause() : play()
    }
    
    private func loadSchedule() {
        guard let url = URL(string: "https://j.prioridad.cl/radiolavoz/api/schedule") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let d = data,
                  let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else { return }
            DispatchQueue.main.async {
                if let live = json["liveNow"] as? [String: Any],
                   let title = live["title"] as? String {
                    self?.currentTitle = title
                } else {
                    self?.currentTitle = "Música continua"
                }
            }
        }.resume()
    }
    
    deinit {
        playerObserver?.invalidate()
    }
}
