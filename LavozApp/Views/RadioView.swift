import SwiftUI
import AVKit

struct RadioView: View {
    @ObservedObject private var player = RadioPlayer.shared

    @State private var selectedDay: String = {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let keys = ["sunday","monday","tuesday","wednesday","thursday","friday","saturday"]
        return keys[weekday - 1]
    }()
    @State private var schedule: [ShowInfo] = []
    @State private var scheduleLoading = true

    private let days: [(key: String, label: String)] = [
        ("monday","LUN"),("tuesday","MAR"),("wednesday","MIÉ"),
        ("thursday","JUE"),("friday","VIE"),("saturday","SÁB"),("sunday","DOM")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    topBar
                    heroSection
                    playerCard
                        .padding(.horizontal, 20)

                    if let show = player.liveShow {
                        liveNowCard(show)
                            .padding(.top, 20)
                            .padding(.horizontal, 20)
                    }

                    programacionSection
                        .padding(.top, 28)

                    shareRow
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    taglineSection
                        .padding(.bottom, 32)
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
        .onAppear {
            if !player.isPlaying { player.play() }
            loadSchedule(day: selectedDay)
        }
        .onChange(of: selectedDay) { day in
            loadSchedule(day: day)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            HStack(spacing: 5) {
                Circle().fill(Color.lvpRed).frame(width: 7, height: 7)
                Text("EN VIVO")
                    .font(.lvpMicro)
                    .tracking(1.2)
                    .foregroundColor(.lvpRed)
            }
            Spacer()
            Text("Pucón, Chile")
                .font(.lvpMicro)
                .foregroundColor(.lvpTextMuted)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(Color.lvpSurface)
        .overlay(Rectangle().fill(Color.lvpGray200).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                Rectangle().fill(Color.lvpRed).frame(height: 1.5).frame(maxWidth: 50)
                Text("RADIO")
                    .font(.custom("Bebas Neue", size: 16))
                    .tracking(5)
                    .foregroundColor(.lvpRed)
                Rectangle().fill(Color.lvpRed).frame(height: 1.5).frame(maxWidth: 50)
            }
            Text("LA VOZ")
                .font(.custom("Anton", size: 72))
                .foregroundColor(.lvpRed)
                .lineSpacing(0)
            Text("DE PUCÓN")
                .font(.custom("Bebas Neue", size: 28))
                .tracking(6)
                .foregroundColor(.lvpDark)
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.lvpRed.opacity(0.5))
                        .frame(width: 4, height: [16,28,12,36,8,24,14][i])
                }
            }
            .padding(.top, 6)
        }
        .padding(.top, 24)
        .padding(.bottom, 24)
    }

    // MARK: - Player Card

    private var playerCard: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                if player.hasVideo {
                    RadioVideoView(player: player.player)
                        .frame(height: 200)
                } else {
                    videoFallback
                        .frame(height: 200)
                }

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

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.lvpRed)
                                .frame(width: 3, height: player.isPlaying ? [6,18,10,24,14,20,8][i] : 4)
                                .animation(
                                    .easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.12),
                                    value: player.isPlaying
                                )
                        }
                    }
                    .frame(height: 26)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Al aire ahora")
                            .font(.lvpMicro)
                            .tracking(1.5)
                            .foregroundColor(.lvpRed)
                        Text(player.currentTitle)
                            .font(.custom("Bebas Neue", size: 18))
                            .foregroundColor(.lvpDark)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Button(action: { player.toggle() }) {
                    HStack(spacing: 10) {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                        Text(player.isPlaying ? "Pausar" : "Escuchar en vivo")
                            .font(.custom("Bebas Neue", size: 20))
                            .tracking(2)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.lvpRed)
                    .cornerRadius(8)
                    .shadow(color: .lvpRed.opacity(0.4), radius: 12, y: 4)
                }
                .padding(.horizontal, 16)

                VolumeSlider()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            .background(Color.lvpSurface)
        }
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lvpGray200, lineWidth: 1))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    // MARK: - Video Fallback (igual que el sitio web: solo audio)

    private var videoFallback: some View {
        ZStack {
            Color.white
            VStack(spacing: 10) {
                AsyncImage(url: URL(string: "https://j.prioridad.cl/radiolavoz/img/logo-radio-la-voz.png")) { img in
                    img.resizable().scaledToFit()
                } placeholder: {
                    Image(systemName: "radio")
                        .font(.system(size: 36))
                        .foregroundColor(.lvpRed)
                }
                .frame(maxWidth: 180, maxHeight: 70)

                HStack(spacing: 6) {
                    Circle().fill(Color.white).frame(width: 7, height: 7)
                    Text("En vivo · solo audio")
                        .font(.lvpBadge)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.lvpRed)
                .cornerRadius(100)

                Text("Pucón, Chile")
                    .font(.lvpMicro)
                    .tracking(1)
                    .foregroundColor(.lvpTextMuted)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Al Aire Ahora

    private func liveNowCard(_ show: ShowInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Circle().fill(Color.lvpRed).frame(width: 8, height: 8)
                Text("AL AIRE AHORA")
                    .font(.lvpMicro)
                    .tracking(1.5)
                    .foregroundColor(.lvpRed)
            }

            VStack(spacing: 0) {
                AsyncImage(url: show.thumbnailURL) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Color.lvpGray100
                        .overlay(Image(systemName: "photo").foregroundColor(.lvpGray500))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipped()

                VStack(alignment: .leading, spacing: 8) {
                    Text("🔴  \(show.time) – \(show.end) hrs")
                        .font(.custom("Bebas Neue", size: 16))
                        .foregroundColor(.lvpRed)

                    Text(show.title)
                        .font(.custom("Anton", size: 22))
                        .foregroundColor(.lvpDark)
                        .lineLimit(2)

                    if !show.desc.isEmpty {
                        Text(show.desc)
                            .font(.lvpBodySmall)
                            .foregroundColor(.lvpTextSecondary)
                            .lineLimit(3)
                    }

                    Button(action: { player.play() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill").font(.caption2)
                            Text("Escuchar ahora")
                                .font(.lvpCaption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.lvpRed)
                        .cornerRadius(4)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)

                if let next = player.nextShow {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().fill(Color.lvpBlue).frame(width: 28, height: 28)
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        AsyncImage(url: next.thumbnailURL) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Color.lvpGray100
                        }
                        .frame(width: 56, height: 35)
                        .cornerRadius(3)
                        .clipped()

                        VStack(alignment: .leading, spacing: 1) {
                            Text("A continuación")
                                .font(.lvpMicro)
                                .tracking(1)
                                .foregroundColor(.lvpBlue)
                            Text(next.title)
                                .font(.custom("Bebas Neue", size: 15))
                                .foregroundColor(.lvpDark)
                                .lineLimit(1)
                            Text("⏰  \(next.time) hrs")
                                .font(.lvpMicro)
                                .foregroundColor(.lvpTextMuted)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.lvpSurface)
                    .overlay(Rectangle().fill(Color.lvpGray200).frame(height: 1), alignment: .top)
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lvpGray200))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        }
    }

    // MARK: - Programación

    private var programacionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 4) {
                Text("PROGRAMACIÓN")
                    .font(.custom("Bebas Neue", size: 14))
                    .tracking(3)
                    .foregroundColor(.lvpRed)
                Text("La parrilla de la semana")
                    .font(.custom("Anton", size: 22))
                    .foregroundColor(.lvpDark)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(days, id: \.key) { day in
                        Button(action: { selectedDay = day.key }) {
                            Text(day.label)
                                .font(.lvpBadge)
                                .tracking(1)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(selectedDay == day.key ? Color.lvpRed : Color.white)
                                .foregroundColor(selectedDay == day.key ? .white : .lvpGray500)
                        }
                        if day.key != days.last?.key {
                            Rectangle().fill(Color.lvpGray200).frame(width: 1, height: 40)
                        }
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.lvpGray200))
                .cornerRadius(6)
                .padding(.horizontal, 20)
            }

            if scheduleLoading {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .padding(.vertical, 32)
            } else if schedule.isEmpty {
                Text("No hay programación para este día")
                    .font(.lvpBodySmall)
                    .foregroundColor(.lvpTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                VStack(spacing: 12) {
                    ForEach(schedule) { show in
                        showCard(show)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Show Card

    private func showCard(_ show: ShowInfo) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                AsyncImage(url: show.thumbnailURL) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Color.lvpGray100
                        .overlay(Image(systemName: "photo").foregroundColor(.lvpGray500))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .clipped()

                if show.isLive {
                    HStack(spacing: 4) {
                        Circle().fill(Color.white).frame(width: 5, height: 5)
                        Text("En vivo")
                            .font(.lvpBadge)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.lvpRed)
                    .cornerRadius(3)
                    .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(show.time) – \(show.end)")
                    .font(.custom("Bebas Neue", size: 16))
                    .foregroundColor(.lvpRed)
                Text(show.title)
                    .font(.custom("Anton", size: 18))
                    .foregroundColor(.lvpDark)
                    .lineLimit(2)
                if !show.desc.isEmpty {
                    Text(show.desc)
                        .font(.lvpBodySmall)
                        .foregroundColor(.lvpTextSecondary)
                        .lineLimit(2)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(show.isLive ? Color.lvpRed : Color.lvpGray200,
                        lineWidth: show.isLive ? 1.5 : 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - Share Row

    private var shareRow: some View {
        HStack(spacing: 8) {
            Text("COMPARTIR")
                .font(.lvpMicro)
                .tracking(1.2)
                .foregroundColor(.lvpTextMuted)
            shareBtn("facebook", color: "#1877f2")
            shareBtn("twitter", color: "#000000")
            shareBtn("whatsapp", color: "#25d366")
            shareBtn("telegram", color: "#0088cc")
        }
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

    // MARK: - Tagline

    private var taglineSection: some View {
        VStack(spacing: 4) {
            Text("INFORMAMOS · CONECTAMOS · ACOMPAÑAMOS")
                .font(.lvpMicro)
                .tracking(2.5)
                .foregroundColor(.lvpTextMuted)
                .multilineTextAlignment(.center)
            Text("La radio que se ve y se escucha desde Pucón")
                .font(.lvpBodySmall)
                .foregroundColor(.lvpTextMuted)
        }
        .padding(.top, 24)
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private func loadSchedule(day: String) {
        scheduleLoading = true
        RadioPlayer.shared.fetchSchedule(day: day) { shows in
            schedule = shows
            scheduleLoading = false
        }
    }
}

// MARK: - Video Player Wrapper

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

// MARK: - Volume Slider

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
