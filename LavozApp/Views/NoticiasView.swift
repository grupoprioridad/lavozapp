import SwiftUI

// MARK: - Main View

struct NoticiasView: View {
    @StateObject private var service = NoticiasService()

    var body: some View {
        NavigationView {
            ZStack {
                Color.lvpSurface.ignoresSafeArea()

                if service.isLoading && service.noticias.isEmpty {
                    skeletonList
                } else if !service.noticias.isEmpty {
                    noticiasList
                } else if let error = service.error {
                    errorView(error)
                }
            }
            .navigationTitle("Noticias de Pucón")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Noticias de Pucón")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.lvpDark)
                }
            }
        }
        .task { await service.fetch() }
    }

    // MARK: Noticias list

    private var noticiasList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(service.noticias.enumerated()), id: \.element.id) { index, noticia in
                    if index == 0 {
                        NoticiaFeaturedCard(noticia: noticia)
                    } else {
                        NoticiaCard(noticia: noticia)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .refreshable { await service.fetch() }
    }

    // MARK: Skeleton

    private var skeletonList: some View {
        ScrollView {
            VStack(spacing: 16) {
                NoticiaSkeletonCard(tall: true)
                ForEach(0..<4, id: \.self) { _ in NoticiaSkeletonCard(tall: false) }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .allowsHitTesting(false)
    }

    // MARK: Error

    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 52))
                .foregroundColor(.lvpGray200)
            Text("Sin conexión")
                .font(.title3.weight(.semibold))
                .foregroundColor(.lvpDark)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.lvpTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                Task { await service.fetch() }
            } label: {
                Text("Reintentar")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.lvpRed)
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Featured Card (primera noticia)

struct NoticiaFeaturedCard: View {
    let noticia: NoticiaItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero image con título encima del gradiente
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: noticia.imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    imagePlaceholder
                }
                .frame(height: 260)
                .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.15), .black.opacity(0.8)],
                    startPoint: UnitPoint(x: 0.5, y: 0.3),
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 8) {
                    Label("DESTACADO", systemImage: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.lvpRed)
                        .cornerRadius(4)

                    Text(noticia.titulo)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .shadow(color: .black.opacity(0.4), radius: 3)
                }
                .padding(16)
            }
            .frame(height: 260)

            // Contenido
            VStack(alignment: .leading, spacing: 10) {
                Text(noticia.fechaDisplay.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(.lvpRed)

                if !noticia.extracto.isEmpty {
                    Text(noticia.extracto)
                        .font(.system(size: 14))
                        .foregroundColor(.lvpTextSecondary)
                        .lineLimit(3)
                }

                readMoreLink(url: noticia.url, size: 14)
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.09), radius: 14, x: 0, y: 5)
        .clipped()
    }
}

// MARK: - Standard Card

struct NoticiaCard: View {
    let noticia: NoticiaItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Imagen
            AsyncImage(url: noticia.imageURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                imagePlaceholder
            }
            .frame(height: 190)
            .clipped()

            // Contenido
            VStack(alignment: .leading, spacing: 8) {
                Text(noticia.fechaDisplay.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(.lvpRed)

                Text(noticia.titulo)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.lvpDark)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if !noticia.extracto.isEmpty {
                    Text(noticia.extracto)
                        .font(.system(size: 13))
                        .foregroundColor(.lvpTextSecondary)
                        .lineLimit(3)
                }

                readMoreLink(url: noticia.url, size: 13)
            }
            .padding(14)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Skeleton Card

struct NoticiaSkeletonCard: View {
    let tall: Bool
    @State private var animating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            shimmer.frame(height: tall ? 260 : 190)

            VStack(alignment: .leading, spacing: 10) {
                shimmer.frame(width: 100, height: 11).cornerRadius(4)
                shimmer.frame(maxWidth: .infinity).frame(height: 17).cornerRadius(4)
                shimmer.frame(maxWidth: .infinity).frame(height: 17).cornerRadius(4)
                shimmer.frame(width: 220, height: 17).cornerRadius(4)
                shimmer.frame(width: 120, height: 13).cornerRadius(4)
            }
            .padding(14)
        }
        .background(Color.white)
        .cornerRadius(tall ? 14 : 12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                animating = true
            }
        }
    }

    private var shimmer: some View {
        LinearGradient(
            colors: animating
                ? [Color.lvpGray100, Color.lvpGray200, Color.lvpGray100]
                : [Color.lvpGray200, Color.lvpGray100, Color.lvpGray200],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Shared helpers

private var imagePlaceholder: some View {
    Rectangle()
        .fill(Color.lvpGray100)
        .overlay(
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundColor(.lvpGray200)
        )
}

private func readMoreLink(url: URL, size: CGFloat) -> some View {
    Link(destination: url) {
        HStack(spacing: 4) {
            Text("Leer nota completa")
            Image(systemName: "arrow.right")
                .font(.system(size: size - 1, weight: .semibold))
        }
        .font(.system(size: size, weight: .semibold))
        .foregroundColor(.lvpRed)
    }
}
