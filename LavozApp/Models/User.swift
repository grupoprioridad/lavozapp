import Foundation

struct LVPUser: Codable {
    let id: Int
    let email: String
    let nombre: String?
    let foto: String?
    let token: String
    let suscripcionActiva: Bool
    let suscripcionExpira: String?
    let qrData: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, nombre, foto, token
        case suscripcionActiva = "suscripcion_activa"
        case suscripcionExpira = "suscripcion_expira"
        case qrData = "qr_data"
    }
}

struct AuthLoginResponse: Codable {
    let success: Bool
    let message: String?
}

struct AuthVerifyResponse: Codable {
    let success: Bool
    let message: String?
    let token: String?
    let user: LVPUser?
}

struct PerfilResponse: Codable {
    let success: Bool
    let usuario: LVPUser?
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
}
