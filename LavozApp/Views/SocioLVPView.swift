import SwiftUI
import CoreImage.CIFilterBuiltins

struct SocioLVPView: View {
    @EnvironmentObject var auth: AuthService
    @State private var email = ""
    @State private var codigo = ""
    @State private var mostrarCodigo = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if !auth.isLoggedIn {
                        loginSection
                    } else if let p = auth.perfil {
                        credencialSection(p)
                    } else {
                        ProgressView()
                            .onAppear { Task { await auth.loadPerfil() } }
                    }
                }
                .padding(.vertical, 24)
            }
            .background(Color.lvpBackground)
            .navigationTitle("Socio LVP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Socio LVP")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.lvpDark)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salir") { auth.logout() }
                        .font(.lvpBodyMedium)
                        .foregroundColor(.lvpRed)
                        .opacity(auth.isLoggedIn ? 1 : 0)
                        .allowsHitTesting(auth.isLoggedIn)
                }
            }
        }
    }
    
    // ── LOGIN ──
    private var loginSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 48))
                .foregroundColor(.lvpRed)
            
            Text("Red de Beneficios LVP")
                .font(.lvpHeadline)
                .foregroundColor(.lvpDark)
            
            Text("Ingresa tu correo registrado para acceder\na los beneficios exclusivos para socios.")
                .font(.lvpBodyMedium)
                .foregroundColor(.lvpTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if !mostrarCodigo {
                // Email step
                VStack(alignment: .leading, spacing: 6) {
                    Text("Correo electrónico")
                        .font(.lvpCaption)
                        .foregroundColor(.lvpTextSecondary)
                    TextField("[email protected]", text: $email)
                        .font(.lvpBody)
                        .foregroundColor(.lvpDark)
                        .padding(14)
                        .background(Color.lvpGray100)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.lvpGray500.opacity(0.4)))
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                .padding(.horizontal, 24)
                
                Button(action: login) {
                    ZStack {
                        if auth.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Enviar código")
                                .font(.lvpBody.weight(.semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(email.isEmpty ? Color.lvpGray200 : Color.lvpRed)
                    .cornerRadius(8)
                }
                .disabled(email.isEmpty || auth.isLoading)
                .padding(.horizontal, 24)
                
            } else {
                // Code step
                VStack(alignment: .leading, spacing: 6) {
                    Text("Código de verificación")
                        .font(.lvpCaption)
                        .foregroundColor(.lvpTextSecondary)
                    Text("Enviamos un código a \(auth.emailIngresado)")
                        .font(.lvpBodySmall)
                        .foregroundColor(.lvpTextMuted)
                    TextField("Ingresa el código de 6 dígitos", text: $codigo)
                        .font(.lvpBody)
                        .foregroundColor(.lvpDark)
                        .padding(14)
                        .background(Color.lvpGray100)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.lvpGray500.opacity(0.4)))
                        .keyboardType(.numberPad)
                }
                .padding(.horizontal, 24)
                
                Button(action: verify) {
                    ZStack {
                        if auth.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Verificar")
                                .font(.lvpBody.weight(.semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(codigo.isEmpty ? Color.lvpGray200 : Color.lvpRed)
                    .cornerRadius(8)
                }
                .disabled(codigo.isEmpty || auth.isLoading)
                .padding(.horizontal, 24)
                
                Button("Reenviar código") {
                    Task { await auth.resend() }
                }
                .font(.lvpBodySmall)
                .foregroundColor(.lvpRed)
                .disabled(auth.isLoading)
            }
            
            if let error = auth.error {
                Text(error)
                    .font(.lvpBodySmall)
                    .foregroundColor(.lvpRed)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
    
    // ── CREDENCIAL ──
    private func credencialSection(_ p: LVPUser) -> some View {
        VStack(spacing: 20) {
            // Credencial card
            VStack(spacing: 0) {
                // Red header
                VStack(spacing: 4) {
                    Text("LA VOZ DE PUCÓN")
                        .font(.lvpMicro)
                        .spaced(2)
                        .foregroundColor(.white.opacity(0.8))
                    Text("SOCIOS")
                        .font(.custom("Anton", size: 28))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.lvpRed)
                
                // Info
                VStack(spacing: 4) {
                    Text(p.nombreDisplay)
                        .font(.lvpHeadline)
                        .foregroundColor(.lvpDark)
                    
                    Text("Socio #\(String(p.id).padding(toLength: 5, withPad: "0", startingAt: 0))")
                        .font(.lvpBodySmall)
                        .foregroundColor(.lvpTextSecondary)
                    
                    Text(p.email)
                        .font(.lvpBodySmall)
                        .foregroundColor(.lvpTextMuted)
                }
                .padding(.bottom, 16)
                
                // Status
                HStack {
                    Image(systemName: p.suscripcionActiva ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .foregroundColor(p.suscripcionActiva ? .lvpGreen : .lvpRed)
                    Text(p.suscripcionActiva ? "MEMBRESÍA ACTIVA" : "MEMBRESÍA INACTIVA")
                        .font(.lvpBadge)
                        .spaced(1.5)
                        .foregroundColor(p.suscripcionActiva ? .lvpGreen : .lvpRed)
                }
                .padding(.bottom, 4)
                
                if let expira = p.suscripcionExpira {
                    Text("Válida hasta \(formatDate(expira))")
                        .font(.lvpCaption)
                        .foregroundColor(.lvpTextMuted)
                }
                
                // QR — generated locally from the verification URL
                qrView(for: p.qrData)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lvpGray200))
            .padding(.horizontal, 24)
            
            Text("Usa esta credencial para canjear beneficios")
                .font(.lvpCaption)
                .foregroundColor(.lvpTextSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 24)
            
            // Beneficios
            if !auth.beneficios.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("BENEFICIOS DISPONIBLES")
                        .font(.lvpCaption)
                        .spaced(1.5)
                        .foregroundColor(.lvpRed)
                        .padding(.horizontal, 24)
                    
                    ForEach(auth.beneficios) { b in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.lvpRed.opacity(0.1))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "gift.fill")
                                        .foregroundColor(.lvpRed)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(b.titulo)
                                    .font(.lvpBody.weight(.semibold))
                                    .foregroundColor(.lvpDark)
                                Text(b.comercio)
                                    .font(.lvpBodySmall)
                                    .foregroundColor(.lvpTextSecondary)
                            }
                            
                            Spacer()
                            
                            Text("\(b.stock)")
                                .font(.lvpBadge)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(b.stock > 0 ? Color.lvpRed : Color.lvpGray500)
                                .cornerRadius(4)
                        }
                        .padding(12)
                        .background(Color.lvpSurface)
                        .cornerRadius(8)
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
    }
    
    private func login() {
        Task {
            if await auth.login(email: email) { mostrarCodigo = true }
        }
    }
    
    private func verify() {
        Task { _ = await auth.verify(codigo: codigo) }
    }
    
    @ViewBuilder
    private func qrView(for data: String?) -> some View {
        if let data, !data.isEmpty, let img = generateQR(from: data) {
            Image(uiImage: img)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.lvpGray100)
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "qrcode")
                        .font(.largeTitle)
                        .foregroundColor(.lvpGray500)
                )
        }
    }

    private func generateQR(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func formatDate(_ s: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        if let d = f.date(from: s) {
            f.dateFormat = "dd/MM/yyyy"
            f.locale = Locale(identifier: "es_CL")
            return f.string(from: d)
        }
        return s
    }
}
