import Foundation

/// Hebt in einer Log-Nachricht die Teile hervor, nach denen man beim Lesen
/// sucht: URLs, IPs, Zahlen mit Einheit, UUIDs, Pfade, Zitate und key=value.
/// Alles, was nicht getroffen wird, wird escaped -- die Ausgabe ist sicheres HTML.
public enum LogHighlighter {

    // Reihenfolge = Vorrang. URL vor Pfad (sonst wird "//host/x" zum Pfad),
    // UUID vor Zahl, IP vor Zahl.
    private nonisolated(unsafe) static let tokenRe = try! NSRegularExpression(pattern: [
        #"(?<url>\b[A-Za-z][A-Za-z0-9+.\-]*://[^\s"'<>]+)"#,
        #"(?<str>"(?:[^"\\\n]|\\.)*")"#,
        #"(?<uuid>\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b)"#,
        #"(?<ip>(?<![\w.])(?:\d{1,3}\.){3}\d{1,3}(?::\d{1,5})?(?![\w.]))"#,
        #"(?<key>(?<![\w.\-/])[A-Za-z_][\w.\-]*(?==[^=\s]))"#,
        #"(?<path>(?<![\w.:/~])~?/(?:[\w.@+\-]+/)*[\w.@+\-]+/?)"#,
        #"(?<num>(?<![\w.\-])-?\d+(?:[.,]\d+)?(?:ms|µs|us|ns|s|m|h|%|[KMGT]i?B|B)?(?![\w.]))"#
    ].joined(separator: "|"))

    private static let groups = ["url", "str", "uuid", "ip", "key", "path", "num"]

    public static func highlight(_ text: String) -> String {
        let ns = text as NSString
        var out = ""
        out.reserveCapacity(text.utf8.count + 64)
        var cursor = 0
        for m in tokenRe.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            guard let name = groups.first(where: { m.range(withName: $0).location != NSNotFound }) else { continue }
            let r = m.range
            if r.location > cursor {
                out += HTMLEscape.escape(ns.substring(with: NSRange(location: cursor, length: r.location - cursor)))
            }
            out += "<span class=\"lg-\(name)\">\(HTMLEscape.escape(ns.substring(with: r)))</span>"
            cursor = r.location + r.length
        }
        if cursor < ns.length {
            out += HTMLEscape.escape(ns.substring(from: cursor))
        }
        return out
    }
}
