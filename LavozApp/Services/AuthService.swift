import Foundation
import SwiftUI

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isLoggedIn = false
    @Published var currentUser: LVPUser?
    @Published var perfil: LVPUser?
    @Published var beneficios: [Beneficio] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var requiereCodigo = false
    @Published var emailIngresado = ""

    private let key = "lvp_user_data"

    private init() { load() }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let user = try? JSONDecoder().decode(LVPUser.self, from: data) else { return }
        currentUser = user
        isLoggedIn = true
    }

    private func save(_ user: LVPUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: key)
        }
        currentUser = user
        isLoggedIn = true
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: key)
        currentUser = nil; perfil = nil; beneficios = []
        isLoggedIn = false; requiereCodigo = false; emailIngresado = ""
    }

    func login(email: String) async -> Bool {
        isLoading = true; error = nil; defer { isLoading = false }
        do {
            let resp = try await APIService.shared.login(email: email)
            if resp.success {
                emailIngresado = email; requiereCodigo = true; return true
            } else {
                error = resp.message ?? "Error al iniciar sesión"; return false
            }
        } catch { self.error = error.localizedDescription; return false }
    }

    func verify(codigo: String) async -> Bool {
        isLoading = true; error = nil; defer { isLoading = false }
        do {
            let resp = try await APIService.shared.verify(email: emailIngresado, codigo: codigo)
            if resp.success, let token = resp.token, let u = resp.user {
                // Build a minimal user with the token; loadPerfil will fill in the rest
                let user = LVPUser(
                    id: u.id,
                    email: u.email,
                    nombre: u.nombre,
                    token: token,
                    telefono: nil,
                    suscripcionActiva: false,
                    suscripcionExpira: nil,
                    qrData: nil
                )
                save(user)
                requiereCodigo = false
                await loadPerfil()
                return true
            } else {
                error = resp.message ?? "Código inválido"; return false
            }
        } catch { self.error = error.localizedDescription; return false }
    }

    func resend() async -> Bool {
        isLoading = true; defer { isLoading = false }
        do { return try await APIService.shared.resend(email: emailIngresado).success }
        catch { self.error = error.localizedDescription; return false }
    }

    func loadPerfil() async {
        guard let token = currentUser?.token else { return }
        do {
            async let perfilTask = APIService.shared.getPerfil(token: token)
            async let beneficiosTask = APIService.shared.getBeneficios(token: token)
            let (resp, bResp) = try await (perfilTask, beneficiosTask)

            if let id = resp.id, let email = resp.email {
                let updated = LVPUser(
                    id: id,
                    email: email,
                    nombre: resp.nombre,
                    token: token,
                    telefono: resp.telefono,
                    suscripcionActiva: resp.suscripcionActiva ?? false,
                    suscripcionExpira: resp.suscripcionExpira,
                    qrData: resp.qrData
                )
                save(updated)
                perfil = updated
            }
            beneficios = bResp.beneficios ?? []
        } catch APIError.unauthorized {
            logout()
        } catch {
            print("Perfil error: \(error)")
        }
    }
}
