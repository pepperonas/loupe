import Foundation
import UniformTypeIdentifiers

/// Log-Dateien als Tabelle: Zeit | Level | Quelle | Nachricht, Fehler hervorgehoben,
/// Stacktraces am Eintrag, bei grossen Dateien die NEUESTEN Zeilen.
public struct LogPreviewRenderer: PreviewRenderer {

    /// Bei grossen Logs werden nur die letzten 4 MB gelesen.
    public static let tailBytes = 4 * 1024 * 1024

    public static var readStrategy: PreviewReadStrategy { .tail(maxBytes: tailBytes) }

    public static var supportedTypes: [UTType] {
        var types: [UTType] = []
        for id in ["com.apple.log", "public.log"] {
            if let t = UTType(id), !types.contains(t) { types.append(t) }
        }
        if let t = UTType(filenameExtension: "log"), !types.contains(t) { types.append(t) }
        return types
    }

    // Bewusst nur ".log": ".out", ".err" und rotierte "app.log.1" bekommen von
    // macOS einen dynamischen Typ, fuer den Quick Look keine Erweiterung ruft --
    // und ein eigener Typ fuer ".out" wuerde Binaerdateien wie "a.out" zu Text machen.

    public init() {}

    public func renderHTML(input: PreviewInput, settings: LoupeSettings) -> String {
        let text = String(decoding: input.data, as: UTF8.self)
        let tailed = input.skippedBytesAtStart > 0
        // Mit bekannter Umbruchzahl bleiben die Nummern absolut; sonst zaehlt der
        // Ausschnitt ab 1 (die angeschnittene erste Zeile ist Nummer 0).
        let first = tailed ? (input.skippedLineBreaks.map { $0 + 1 } ?? 0) : 1
        let doc = LogParser.parse(text: text, startsMidLine: tailed, firstLineNumber: first)
        let body = renderBody(document: doc,
                              relativeLineNumbers: tailed && input.skippedLineBreaks == nil,
                              filename: input.url.lastPathComponent,
                              totalBytes: input.data.count + input.skippedBytesAtStart,
                              skippedBytes: input.skippedBytesAtStart,
                              settings: settings)
        return HTMLDocument.wrap(body: body,
                                 title: input.url.lastPathComponent,
                                 css: CSSGenerator.generateLogCSS(settings: settings),
                                 csp: HTMLDocument.contentSecurityPolicy)
    }

    public func renderBody(document doc: LogDocument,
                           relativeLineNumbers: Bool = false,
                           filename: String,
                           totalBytes: Int,
                           skippedBytes: Int,
                           settings: LoupeSettings) -> String {
        var html = "<div class=\"lp-code-container lg\">\n"

        var notes: [String] = []
        if skippedBytes > 0 {
            notes.append("Nur das Ende der Datei wird gezeigt – die ersten \(formatSize(skippedBytes)) wurden nicht gelesen.")
        }
        if relativeLineNumbers {
            notes.append("Zeilennummern sind relativ zum gezeigten Ausschnitt.")
        }
        if doc.droppedLines > 0 {
            notes.append("\(doc.droppedLines) ältere Zeilen ausgelassen, gezeigt werden die neuesten \(doc.totalLines).")
        }
        if !notes.isEmpty {
            html += "<div class=\"lp-banner lp-banner-notice\">\(HTMLEscape.escape(notes.joined(separator: " ")))</div>\n"
        }

        html += toolbar(doc: doc, filename: filename, totalBytes: totalBytes)

        if doc.entries.isEmpty {
            html += "<div class=\"lp-code-scroll\"><div class=\"lg-empty\">Die Datei ist leer.</div></div>\n</div>\n"
            return html
        }

        let hasTime = doc.entries.contains { $0.timestamp != nil }
        let hasLevel = doc.entries.contains { $0.level != nil || $0.access != nil }
        let hasSource = doc.entries.contains { $0.source != nil }
        let highlight = settings.enableSyntaxHighlighting
        let span = 1 + (hasTime ? 1 : 0) + (hasLevel ? 1 : 0) + (hasSource ? 1 : 0)

        html += "<div class=\"lp-code-scroll\">\n<table class=\"lg-table\"><tbody>\n"
        for e in doc.entries {
            let lvlClass = e.level.map { " lg-lvl-\($0.cssName)" } ?? ""
            html += "<tr class=\"lg-row\(lvlClass)\">"
            html += "<td class=\"lp-line-no\">\(e.lineNumber)</td>"
            if hasTime { html += "<td class=\"lg-ts\">\(HTMLEscape.escape(e.timestamp ?? ""))</td>" }
            if hasLevel { html += "<td class=\"lg-lvl\">\(badge(for: e))</td>" }
            if hasSource { html += "<td class=\"lg-src\">\(HTMLEscape.escape(e.source ?? ""))</td>" }
            html += "<td class=\"lg-msg\">\(message(for: e, highlight: highlight))</td></tr>\n"

            for c in e.continuation {
                html += "<tr class=\"lg-cont\(lvlClass)\">"
                html += "<td class=\"lp-line-no\">\(c.lineNumber)</td>"
                let content = c.text.isEmpty ? "&ZeroWidthSpace;" : (highlight ? LogHighlighter.highlight(c.text) : HTMLEscape.escape(c.text))
                html += "<td class=\"lg-msg\"\(span > 1 ? " colspan=\"\(span)\"" : "")>\(content)</td></tr>\n"
            }
        }
        html += "</tbody></table>\n</div>\n</div>\n"
        return html
    }

    // MARK: - Teile

    private func toolbar(doc: LogDocument, filename: String, totalBytes: Int) -> String {
        var left = "<span class=\"lp-filename\">\(HTMLEscape.escape(filename))</span><span class=\"lp-badge\">LOG</span>"
        if let f = doc.dominantFormat, f != .generic {
            left += "<span class=\"lp-badge\">\(HTMLEscape.escape(f.displayName))</span>"
        }
        var right = ""
        // Nur Auffaelliges zaehlen -- "1.200 INFO" ist Rauschen.
        for level in [LogLevel.fatal, .error, .warning] {
            if let n = doc.levelCounts[level], n > 0 {
                right += "<span class=\"lg-count lg-lvl-\(level.cssName)\">\(n) \(level.label)</span>"
            }
        }
        let lines = doc.totalLines
        right += "<span>\(lines) \(lines == 1 ? "Zeile" : "Zeilen")</span>"
        right += "<span>\(formatSize(totalBytes))</span>"
        return """
        <div class="lp-toolbar">
            <div class="lp-toolbar-left">\(left)</div>
            <div class="lp-toolbar-right">\(right)</div>
        </div>

        """
    }

    private func badge(for e: LogEntry) -> String {
        if let a = e.access {
            return "<span class=\"lg-badge lg-status lg-st-\(a.statusClass)\">\(a.status)</span>"
        }
        guard let l = e.level else { return "" }
        return "<span class=\"lg-badge\">\(l.label)</span>"
    }

    private func message(for e: LogEntry, highlight: Bool) -> String {
        if let a = e.access {
            var parts: [String] = []
            if let m = a.method { parts.append("<span class=\"lg-method\">\(HTMLEscape.escape(m))</span>") }
            if let p = a.path {
                let cls = a.method == nil ? "lg-str" : "lg-path"
                parts.append("<span class=\"\(cls)\">\(HTMLEscape.escape(p))</span>")
            }
            if let pr = a.proto { parts.append("<span class=\"lg-proto\">\(HTMLEscape.escape(pr))</span>") }
            if let b = a.bytes, let n = Int(b) { parts.append("<span class=\"lg-bytes\">\(formatSize(n))</span>") }
            if let r = a.referer { parts.append("<span class=\"lg-ref\">← \(HTMLEscape.escape(r))</span>") }
            if let ua = a.userAgent { parts.append("<span class=\"lg-ua\">\(HTMLEscape.escape(ua))</span>") }
            return parts.joined(separator: " ")
        }

        var out = highlight ? LogHighlighter.highlight(e.message) : HTMLEscape.escape(e.message)
        for f in e.fields {
            let cls = f.isString ? "lg-str" : "lg-num"
            if !out.isEmpty { out += " " }
            out += "<span class=\"lg-field\"><span class=\"lg-key\">\(HTMLEscape.escape(f.key))</span>=<span class=\"\(cls)\">\(HTMLEscape.escape(f.value))</span></span>"
        }
        return out.isEmpty ? "&ZeroWidthSpace;" : out
    }

    private func formatSize(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }
}
