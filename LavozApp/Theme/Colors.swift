import SwiftUI

extension Color {
    // La Voz de Pucón Brand
    static let lvpRed = Color(hex: "CC1414")
    static let lvpRedDark = Color(hex: "A50F0F")
    static let lvpBlue = Color(hex: "1B3A72")
    static let lvpBlueLight = Color(hex: "2B5AA0")
    static let lvpBackground = Color(hex: "FFFFFF")
    static let lvpSurface = Color(hex: "F8F8F8")
    static let lvpCard = Color(hex: "FFFFFF")
    static let lvpTextPrimary = Color(hex: "111111")
    static let lvpTextSecondary = Color(hex: "777777")
    static let lvpTextMuted = Color(hex: "AAAAAA")
    static let lvpGray100 = Color(hex: "F2F2F2")
    static let lvpGray200 = Color(hex: "E2E2E2")
    static let lvpGray500 = Color(hex: "777777")
    static let lvpGray700 = Color(hex: "444444")
    static let lvpDark = Color(hex: "111111")
    static let lvpGreen = Color(hex: "22c55e")
    
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var i: UInt64 = 0
        Scanner(string: h).scanHexInt64(&i)
        let a, r, g, b: UInt64
        switch h.count {
        case 3: (a, r, g, b) = (255, (i>>8)*17, (i>>4&0xF)*17, (i&0xF)*17)
        case 6: (a, r, g, b) = (255, i>>16, i>>8&0xFF, i&0xFF)
        case 8: (a, r, g, b) = (i>>24, i>>16&0xFF, i>>8&0xFF, i&0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
