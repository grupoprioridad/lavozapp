import Foundation

enum APIError: LocalizedError {
    case invalidURL, network(Error), decoding(Error), server(String), unauthorized
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL inválida"
        case .network(let e): return "Error de red: \(e.localizedDescription)"
        case .decoding: return "Error al procesar la respuesta del servidor"
        case .server(let m): return m
        case .unauthorized: return "Sesión expirada"
        }
    }
}

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    private let baseURL = "https://socios.lavozdepucon.cl/api"

    func login(email: String) async throws -> AuthLoginResponse {
        try await post("/auth/login", body: ["email": email])
    }

    func verify(email: String, codigo: String) async throws -> AuthVerifyResponse {
        try await post("/auth/verify", body: ["email": email, "codigo": codigo])
    }

    func resend(email: String) async throws -> AuthLoginResponse {
        try await post("/auth/login", body: ["email": email])
    }

    func getPerfil(token: String) async throws -> PerfilResponse {
        try await getAuth("/perfil", token: token)
    }

    func getBeneficios(token: String) async throws -> BeneficiosResponse {
        try await getAuth("/beneficios", token: token)
    }

    private func getAuth<T: Decodable>(_ endpoint: String, token: String) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError.network(URLError(.badServerResponse)) }
        if http.statusCode == 401 { throw APIError.unauthorized }
        guard data.count > 0 else { throw APIError.server("El servidor no respondió correctamente (código \(http.statusCode))") }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func post<T: Decodable>(_ endpoint: String, body: [String: Any]) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError.network(URLError(.badServerResponse)) }
        guard data.count > 0 else { throw APIError.server("El servidor no respondió correctamente (código \(http.statusCode))") }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}
