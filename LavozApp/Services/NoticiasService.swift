import Foundation

@MainActor
class NoticiasService: ObservableObject {
    @Published var noticias: [NoticiaItem] = []
    @Published var isLoading = false
    @Published var error: String?

    func fetch() async {
        guard let url = URL(string: "https://www.lavozdepucon.cl/feed/") else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            noticias = RSSParser.parse(data)
        } catch {
            self.error = "No se pudieron cargar las noticias. Verifica tu conexión."
        }
    }
}

// MARK: - RSS Parser

class RSSParser: NSObject, XMLParserDelegate {
    private var items: [NoticiaItem] = []
    private var currentItem: [String: String] = [:]
    private var currentText = ""
    private var insideItem = false

    static func parse(_ data: Data) -> [NoticiaItem] {
        let delegate = RSSParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.items
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String] = [:]) {
        if elementName == "item" { insideItem = true; currentItem = [:] }
        currentText = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        currentText += string
    }

    func parser(_ parser: XMLParser, foundCDATA block: Data) {
        guard insideItem, let s = String(data: block, encoding: .utf8) else { return }
        currentText += s
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName: String?) {
        guard insideItem else { return }
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName {
        case "title":       currentItem["title"] = text
        case "link":        if currentItem["link"] == nil { currentItem["link"] = text }
        case "pubDate":     currentItem["pubDate"] = text
        case "description": currentItem["description"] = text
        case "item":
            if let item = buildItem() { items.append(item) }
            insideItem = false
        default: break
        }
        currentText = ""
    }

    // MARK: Build

    private func buildItem() -> NoticiaItem? {
        guard let title = currentItem["title"],
              let linkStr = currentItem["link"],
              let url = URL(string: linkStr) else { return nil }

        let html = currentItem["description"] ?? ""
        return NoticiaItem(
            titulo: decodeEntities(title),
            url: url,
            fecha: parseDate(currentItem["pubDate"]),
            imageURL: extractImageURL(html),
            extracto: extractExcerpt(html)
        )
    }

    // MARK: Helpers

    private func parseDate(_ string: String?) -> Date {
        guard let string else { return Date() }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return f.date(from: string) ?? Date()
    }

    private func extractImageURL(_ html: String) -> URL? {
        guard let regex = try? NSRegularExpression(pattern: #"src="(https://[^"]+)""#),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else { return nil }
        return URL(string: String(html[range]))
    }

    private func extractExcerpt(_ html: String) -> String {
        func replace(_ pattern: String, with replacement: String, in s: String) -> String {
            (try? NSRegularExpression(pattern: pattern))?.stringByReplacingMatches(
                in: s, range: NSRange(s.startIndex..., in: s), withTemplate: replacement) ?? s
        }
        var text = html
        text = replace("<img[^>]*>", with: "", in: text)
        text = replace("<[^>]+>", with: "", in: text)
        text = decodeEntities(text)
        text = replace(#"\(Apoya[^)]*\)"#, with: "", in: text)
        text = text.replacingOccurrences(of: "[…]", with: "")
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func decodeEntities(_ text: String) -> String {
        var s = text
        [("&amp;","&"),("&lt;","<"),("&gt;",">"),("&quot;","\""),
         ("&#039;","'"),("&apos;","'"),("&#8217;","\u{2019}"),("&#8216;","\u{2018}"),
         ("&#8220;","\u{201C}"),("&#8221;","\u{201D}"),("&#8230;","…"),
         ("&#038;","&"),("&nbsp;"," "),("&#8211;","–"),("&#8212;","—")
        ].forEach { s = s.replacingOccurrences(of: $0.0, with: $0.1) }
        return s
    }
}
