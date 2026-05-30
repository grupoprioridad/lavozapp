import Foundation

struct NoticiaItem: Identifiable {
    let id = UUID()
    let titulo: String
    let url: URL
    let fecha: Date
    let imageURL: URL?
    let extracto: String

    var fechaDisplay: String {
        NoticiaItem.displayFormatter.string(from: fecha)
    }

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_CL")
        f.dateFormat = "d 'de' MMMM 'de' yyyy"
        return f
    }()
}
