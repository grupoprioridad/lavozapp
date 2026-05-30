import SwiftUI

struct BomberosView: View {
    @ObservedObject private var service = BomberosService.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection

                    if service.isLoading && service.llamados.isEmpty {
                        loadingState
                    } else if let error = service.error, service.llamados.isEmpty {
                        errorState(error)
                    } else if service.llamados.isEmpty {
                        emptyState
                    } else {
                        llamadosList
                    }
                }
            }
            .background(Color.lvpBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Bomberos")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.lvpDark)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await service.fetch() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.lvpRed)
                    }
                    .disabled(service.isLoading)
                }
            }
        }
        .task { await service.fetch() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color(hex: "B71C1C"), Color(hex: "D32F2F"), Color(hex: "E53935")],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 72)
            .overlay(
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Text("🚒")
                            .font(.system(size: 22))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bomberos Pucón")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("Central de Alarmas")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        liveDot
                        Text("En vivo")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.25))
                    .cornerRadius(20)
                }
                .padding(.horizontal, 20)
            )
        }
    }

    private var liveDot: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "FF5252"))
                .frame(width: 8, height: 8)
                .shadow(color: Color(hex: "FF1744").opacity(0.6), radius: 4)
        }
    }

    // MARK: - Llamados List

    private var llamadosList: some View {
        LazyVStack(spacing: 6) {
            ForEach(service.llamados) { llamado in
                llamadaCard(llamado)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 32)
    }

    private func llamadaCard(_ ll: BomberoLlamado) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.lvpRed.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Text(emoji(for: ll.texto))
                        .font(.system(size: 16))
                }

                Text(formattedDate(ll.fecha))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.lvpTextSecondary)

                Spacer()

                Text(timeAgo(ll.fecha))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.lvpRed)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.lvpRed.opacity(0.08))
                    .cornerRadius(10)
            }

            Text(ll.texto)
                .font(.system(size: 13.5))
                .foregroundColor(.lvpTextPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            shareButton(for: ll)
                .padding(.top, 8)
        }
        .padding(14)
        .background(Color(hex: "F2F2F2"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "E0E0E0"), lineWidth: 1)
        )
    }

    private func shareButton(for ll: BomberoLlamado) -> some View {
        let text = "Bomberos Pucón — \(ll.texto)"
        Button {
            let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = scene.windows.first?.rootViewController else { return }
            root.present(av, animated: true)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 10, weight: .semibold))
                Text("Compartir")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.lvpTextMuted)
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(.lvpRed)
                .scaleEffect(1.2)
            Text("Cargando llamados...")
                .font(.lvpBodySmall)
                .foregroundColor(.lvpTextMuted)
        }
        .padding(.top, 60)
    }

    private func errorState(_ msg: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundColor(.lvpGray200)
            Text("Error al cargar")
                .font(.lvpHeadline)
                .foregroundColor(.lvpDark)
            Text(msg)
                .font(.lvpBodySmall)
                .foregroundColor(.lvpTextMuted)
                .multilineTextAlignment(.center)
            Button {
                Task { await service.fetch() }
            } label: {
                Text("Reintentar")
                    .font(.lvpBody.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.lvpRed)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 60)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("✅")
                .font(.system(size: 32))
            Text("Sin llamados recientes")
                .font(.lvpBodySmall)
                .foregroundColor(.lvpTextMuted)
        }
        .padding(.top, 60)
    }

    // MARK: - Helpers

    private func emoji(for texto: String) -> String {
        let t = texto.lowercased()
        if t.contains("estructural") || t.contains("incendio") || t.contains("fuego") { return "🔥" }
        if t.contains("rescate vehicular") || t.contains("colisi") { return "🚗" }
        if t.contains("rescate") || t.contains("caída") || t.contains("caida") { return "🚑" }
        if t.contains("pastizal") || t.contains("forestal") || t.contains("basura") { return "🌿" }
        if t.contains("gas") || t.contains("emanaci") { return "⚠️" }
        if t.contains("eléctric") || t.contains("electric") { return "⚡" }
        if t.contains("químic") || t.contains("haz-mat") || t.contains("combustible") { return "☣️" }
        if t.contains("desastre") || t.contains("terremoto") { return "🌋" }
        return "🚨"
    }

    private func timeAgo(_ fecha: String) -> String {
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let cleaned = fecha.replacingOccurrences(of: " ", with: "T") + "+00:00"
        guard let then = df.date(from: cleaned) ?? ISO8601DateFormatter().date(from: cleaned) ?? dateFromCustom(fecha) else {
            return ""
        }

        let diff = Int(Date().timeIntervalSince(then))
        if diff < 60 { return "Hace momentos" }
        if diff < 3600 { return "Hace \(diff / 60) min" }
        if diff < 86400 { return "Hace \(diff / 3600)h" }
        if diff < 172800 { return "Ayer" }
        return "Hace \(diff / 86400) días"
    }

    private func dateFromCustom(_ s: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.timeZone = TimeZone(abbreviation: "UTC")
        return f.date(from: s)
    }

    private func formattedDate(_ fecha: String) -> String {
        guard let d = dateFromCustom(fecha) else { return fecha }
        let cal = Calendar.current
        let adjusted = cal.date(byAdding: .hour, value: -4, to: d) ?? d
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM, HH:mm 'hrs'"
        f.locale = Locale(identifier: "es_CL")
        return f.string(from: adjusted)
    
}
