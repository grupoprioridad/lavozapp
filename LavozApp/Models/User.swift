import Foundation

struct LVPUser: Codable {
    let id: Int
    let email: String
    let nombre: String?
    let token: String
    let telefono: String?
    let suscripcionActiva: Bool
    let suscripcionExpira: String?
    let qrData: String?

    // Nombre display: the API may return "" instead of null
    var nombreDisplay: String {
        if let n = nombre, !n.isEmpty { return n }
        return "Socio LVP"
    }

    enum CodingKeys: String, CodingKey {
        case id, email, nombre, token, telefono
        case suscripcionActiva = "suscripcion_activa"
        case suscripcionExpira = "suscripcion_expira"
        case qrData = "qr_data"
    }
}

struct AuthLoginResponse: Codable {
    let success: Bool
    let message: String?
}

// Partial user returned inside /auth/verify (no token, no subscription data)
struct VerifyUserData: Codable {
    let id: Int
    let email: String
    let nombre: String?
}

struct AuthVerifyResponse: Codable {
    let success: Bool
    let message: String?
    let token: String?
    let user: VerifyUserData?
}

// Flat response from GET /api/perfil
struct PerfilResponse: Codable {
    let success: Bool
    let id: Int?
    let email: String?
    let nombre: String?
    let telefono: String?
    let suscripcionActiva: Bool?
    let suscripcionExpira: String?
    let qrData: String?

    enum CodingKeys: String, CodingKey {
        case success, id, email, nombre, telefono
        case suscripcionActiva = "suscripcion_activa"
        case suscripcionExpira = "suscripcion_expira"
        case qrData = "qr_data"
    }
}

struct BeneficiosResponse: Codable {
    let success: Bool
    let beneficios: [Beneficio]?
}

struct Beneficio: Codable, Identifiable {
    let id: Int
    let titulo: String
    let comercio: String
    let descripcion: String?
    let imagen: String?
    let stock: Int
    let categoria: String?

    enum CodingKeys: String, CodingKey {
        case id, titulo, comercio, descripcion, imagen
        case stock = "codigos_disponibles"
        case categoria = "categoria_nombre"
    }
}
