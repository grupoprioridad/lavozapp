import SwiftUI
import AVKit

struct RadioView: View {
    @StateObject private var player = RadioPlayer.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // ── TOP BAR ──
                    HStack {
                        HStack(spacing: 6) {
                            Circle().fill(Color.lvpRed).frame(width: 7, height: 7)
                            Text("EN VIVO")
                                .font(.lvpMicro)
                                .kerning(1.2)
                                .foregroundColor(.lvpRed)
                        }
                        Spacer()
                        Text("Pucón, Chile")
                            .font(.lvpMicro)
                            .foregroundColor(.lvpTextMuted)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    // ── HERO: LOGO ──
                    VStack(spacing: 4) {
                        HStack(spacing: 12) {
                            Rectangle().fill(Color.lvpRed).frame(height: 1.5)
                                .frame(maxWidth: 50)
                            Text("RADIO")
                                .font(.custom("Bebas Neue", size: 16))
                                .kerning(5)
                                .foregroundColor(.lvpRed)
                            Rectangle().fill(Color.lvpRed).frame(height: 1.5)
                                .frame(maxWidth: 50)
                        }
                        
                        Text("LA VOZ")
                            .font(.custom("Anton", size: 72))
                            .foregroundColor(.lvpRed)
                            .lineSpacing(0)
                        
                        Text("DE PUCÓN")
                            .font(.custom("Bebas Neue", size: 28))
                            .kerning(6)
                            .foregroundColor(.lvpDark)
                        
                        // Waveform decorativo
                        HStack(spacing: 4) {
                            ForEach(0..<7, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.lvpRed.opacity(0.5))
                                    .frame(width: 4, height: [16,28,12,36,8,24,14][i])
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 28)
                    
                    // ── PLAYER CARD ──
                    VStack(spacing: 0) {
                        // Video area
                        ZStack(alignment: .topTrailing) {
                            RadioVideoView(player: player.player)
                                .frame(height: 200)
                            
                            // Live badge
                            if player.isPlaying {
                                HStack(spacing: 4) {
                                    Circle().fill(Color.white).frame(width: 6, height: 6)
                                    Text("EN VIVO")
                                        .font(.lvpBadge)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.lvpRed)
                                .cornerRadius(4)
                                .padding(8)
                            }
                        }
                        
                        // ── CONTROLS ──
                        VStack(spacing: 12) {
                            // Now playing
                            HStack(spacing: 12) {
                                // Animated waveform
                                HStack(spacing: 3) {
                                    ForEach(0..<7, id: \.self) { i in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.lvpRed)
                                            .frame(width: 3, height: player.isPlaying ? [6,18,10,24,14,20,8][i] : 4)
                                            .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.12), value: player.isPlaying)
                                    }
                                }
                                .frame(height: 26)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Al aire ahora")
                                        .font(.lvpMicro)
                                        .kerning(1.5)
                                        .foregroundColor(.lvpRed)
                                    Text(player.currentTitle)
                                        .font(.custom("Bebas Neue", size: 18))
                                        .foregroundColor(.lvpDark)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            
                            // Play button
                            Button(action: { player.toggle() }) {
                                HStack(spacing: 10) {
                                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.title2)
                                    Text(player.isPlaying ? "Pausar" : "Escuchar en vivo")
                                        .font(.custom("Bebas Neue", size: 20))
                                        .kerning(2)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.lvpRed)
                                .cornerRadius(8)
                                .shadow(color: .lvpRed.opacity(0.4), radius: 12, y: 4)
                            }
                            .padding(.horizontal, 16)
                            
                            // Volume
                            VolumeSlider()
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                        }
                        .background(Color.lvpSurface)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.lvpGray200, lineWidth: 1)
                    )
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
                    .padding(.horizontal, 20)
                    
                    // ── SHARE ──
                    HStack(spacing: 8) {
                        Text("COMPARTIR")
                            .font(.lvpMicro)
                            .kerning(1.2)
                            .foregroundColor(.lvpTextMuted)
                        
                        shareBtn("facebook", color: "#1877f2")
                        shareBtn("twitter", color: "#000000")
                        shareBtn("whatsapp", color: "#25d366")
                        shareBtn("telegram", color: "#0088cc")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // ── TAGLINE ──
                    Text("INFORMAMOS · CONECTAMOS · ACOMPAÑAMOS")
                        .font(.lvpMicro)
                        .kerning(2.5)
                        .foregroundColor(.lvpTextMuted)
                        .padding(.top, 24)
                    
                    Text("La radio que se ve y se escucha desde Pucón")
                        .font(.lvpBodySmall)
                        .foregroundColor(.lvpTextMuted)
                        .padding(.top, 4)
                }
            }
            .background(Color.lvpBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("La Radio")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.lvpDark)
                }
            }
        }
        .onAppear { if !player.isPlaying { player.play() } }
    }
    
    private func shareBtn(_ name: String, color: String) -> some View {
        Button(action: {}) {
            Image(systemName: "square.and.arrow.up")
                .font(.caption)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Color(hex: color))
                .clipShape(Circle())
        }
    }
}

// ── Video Player Wrapper ──
struct RadioVideoView: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let c = AVPlayerViewController()
        c.player = player
        c.showsPlaybackControls = false
        c.videoGravity = .resizeAspectFill
        c.updatesNowPlayingInfoCenter = false
        c.entersFullScreenWhenPlaybackBegins = false
        return c
    }
    
    func updateUIViewController(_ c: AVPlayerViewController, context: Context) {
        c.player = player
    }
}

// ── Volume Slider ──
struct VolumeSlider: View {
    @State private var volume: Float = 0.8
    @State private var isMuted = false
    
    var body: some View {
        HStack(spacing: 10) {
            Button(action: {
                isMuted.toggle()
                RadioPlayer.shared.player.isMuted = isMuted
            }) {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.caption)
                    .foregroundColor(.lvpGray500)
            }
            
            Slider(value: $volume, in: 0...1) { _ in
                RadioPlayer.shared.player.volume = volume
                if volume > 0 && isMuted {
                    isMuted = false
                    RadioPlayer.shared.player.isMuted = false
                }
            }
            .tint(.lvpRed)
        }
    }
}
