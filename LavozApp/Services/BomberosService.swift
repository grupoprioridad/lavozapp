import Foundation

struct BomberoLlamado: Identifiable, Decodable {
    let id: Int
    let texto: String
    let fecha: String
}

struct BomberosResponse: Decodable {
    let ok: Bool
    let llamados: [BomberoLlamado]
}

@MainActor
class BomberosService: ObservableObject {
    static let shared = BomberosService()

    @Published var llamados: [BomberoLlamado] = []
    @Published var isLoading = false
    @Published var error: String?

    private let url = URL(string: "https://bomberos.lavozdepucon.cl/api.php?limit=100")!
    private let token = "6dad417b7bdf970f2b86fc8335c7b9e9d4a220ce2d0400da29615db8979b85ee"

    func fetch() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            var req = URLRequest(url: url)
            req.setValue(token, forHTTPHeaderField: "X-Widget-Token")
            let (data, _) = try await URLSession.shared.data(for: req)
            let res = try JSONDecoder().decode(BomberosResponse.self, from: data)
            if res.ok {
                llamados = res.llamados
            } else {
                self.error = "Error al cargar datos"
            }
        } catch {
            self.error = "No se pudieron cargar los llamados"
        }
    }
}
