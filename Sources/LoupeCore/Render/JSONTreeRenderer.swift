import Foundation

public struct JSONTreeRenderer {
    private let settings: LoupeSettings
    private let openPaths: Set<[Int]>

    public init(settings: LoupeSettings, openPaths: Set<[Int]> = []) {
        self.settings = settings
        self.openPaths = openPaths
    }

    public func renderBody(_ result: ParseResult, sourceBytes: [UInt8]) -> String {
        var out = banner(for: result, sourceBytes: sourceBytes)
        if let root = result.root {
            out += "<div class=\"lp-tree\">\n"
            out += node(root, label: nil, path: [])
            out += "</div>\n"
        }
        return out
    }

    // MARK: - Banner

    private func banner(for result: ParseResult, sourceBytes: [UInt8]) -> String {
        switch result.outcome {
        case .complete:
            return ""
        case .truncatedByLimit(let kind):
            // KEIN Fehler -- wir haben gekuerzt, die Datei ist in Ordnung.
            return """
            <div class="lp-banner lp-banner-notice">\(HTMLEscape.escape(noticeText(kind)))</div>
            """
        case .failed(let position):
            let message = result.diagnostics.last(where: { $0.severity == .error })?.message
                ?? "Die Datei konnte nicht vollständig gelesen werden."
            var html = "<div class=\"lp-banner lp-banner-error\">"
            html += "Zeile \(position.line), Spalte \(position.column): "
            html += HTMLEscape.escape(message)
            let lines = SourceExcerpt.make(bytes: sourceBytes, around: position, contextLines: 1)
            if !lines.isEmpty {
                html += "<div class=\"lp-excerpt\">"
                for line in lines {
                    let number = String(format: "%4d", line.number)
                    html += "\(number) │ \(HTMLEscape.escape(line.text))\n"
                    if let caret = line.caretColumn {
                        html += "     │ \(String(repeating: " ", count: max(0, caret - 1)))"
                        html += "<span class=\"lp-caret\">^</span>\n"
                    }
                }
                html += "</div>"
            }
            html += "</div>"
            return html
        }
    }

    private func noticeText(_ kind: LimitKind) -> String {
        switch kind {
        case .bytes:  return "Datei abgeschnitten — nur der Anfang wurde gelesen. Die Datei selbst ist in Ordnung."
        case .nodes:  return "Sehr großes Dokument — nur ein Teil des Baums wird dargestellt."
        case .children: return "Sehr große Listen — je Container werden höchstens 1.000 Einträge dargestellt."
        case .depth:  return "Sehr tief verschachtelt — ab Ebene 64 wird nicht weiter dargestellt."
        case .stringLength: return "Sehr lange Textwerte wurden für die Anzeige gekürzt."
        }
    }

    // MARK: - Knoten

    /// `label` ist der Schluessel (Objekt), der Index (Array) oder nil (Wurzel).
    private func node(_ value: JSONValue, label: String?, path: [Int]) -> String {
        let prefix = label.map { "<span class=\"lp-key\">\(HTMLEscape.escape($0))</span> : " } ?? ""

        switch value {
        case .null:
            return "<div class=\"lp-node\">\(prefix)<span class=\"lp-null\">null</span></div>\n"
        case .bool(let b):
            return "<div class=\"lp-node\">\(prefix)<span class=\"lp-bool\">\(b)</span></div>\n"
        case .number(let n):
            return "<div class=\"lp-node\">\(prefix)<span class=\"lp-num\">\(HTMLEscape.escape(n))</span></div>\n"
        case .string(let s):
            let escaped = HTMLEscape.escape(s)
            return "<div class=\"lp-node\">\(prefix)<span class=\"lp-str\">\"\(escaped)\"</span></div>\n"

        case .array(let items, let omitted):
            let open = openPaths.contains(path) ? " open" : ""
            var html = "<details\(open) class=\"lp-node\"><summary>"
            html += prefix + "[ ] <span class=\"lp-count\">\(items.count + omitted) Einträge</span>"
            html += peek(arrayItems: items)
            html += "</summary>\n"
            for (index, item) in items.enumerated() {
                html += node(item, label: String(index), path: path + [index])
            }
            if omitted > 0 {
                html += "<div class=\"lp-omitted\">… \(omitted) weitere Einträge nicht dargestellt</div>\n"
            }
            html += "</details>\n"
            return html

        case .object(let members, let omitted):
            let open = openPaths.contains(path) ? " open" : ""
            var html = "<details\(open) class=\"lp-node\"><summary>"
            html += prefix + "{ } <span class=\"lp-count\">\(members.count + omitted) Schlüssel</span>"
            html += peek(objectMembers: members)
            html += "</summary>\n"
            for (index, member) in members.enumerated() {
                html += node(member.value, label: member.key, path: path + [index])
            }
            if omitted > 0 {
                html += "<div class=\"lp-omitted\">… \(omitted) weitere Schlüssel nicht dargestellt</div>\n"
            }
            html += "</details>\n"
            return html
        }
    }

    // MARK: - Vorschau in der zugeklappten Zeile

    /// Ohne diesen Blick muesste man jeden Knoten oeffnen, um zu wissen,
    /// ob er interessant ist (Spec §6).
    private func peek(objectMembers members: [Member]) -> String {
        guard settings.showTypeBadges, !members.isEmpty else { return "" }
        let names = members.prefix(3).map { HTMLEscape.escape($0.key) }
        let more = members.count > 3 ? ", …" : ""
        return "<span class=\"lp-peek\">\(names.joined(separator: ", "))\(more)</span>"
    }

    private func peek(arrayItems items: [JSONValue]) -> String {
        guard settings.showTypeBadges, !items.isEmpty else { return "" }
        let shown = items.prefix(3).map(shortDescription)
        let more = items.count > 3 ? ", …" : ""
        return "<span class=\"lp-peek\">\(shown.joined(separator: ", "))\(more)</span>"
    }

    private func shortDescription(_ value: JSONValue) -> String {
        switch value {
        case .null:            return "null"
        case .bool(let b):     return "\(b)"
        case .number(let n):   return HTMLEscape.escape(n)
        case .string(let s):   return "\"" + HTMLEscape.escape(String(s.prefix(18))) + (s.count > 18 ? "…\"" : "\"")
        case .array(let i, let o):   return "[\(i.count + o)]"
        case .object(let m, let o):  return "{\(m.count + o)}"
        }
    }
}
