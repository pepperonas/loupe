import Foundation
import UniformTypeIdentifiers

/// `.chart`-Dateien (Clone Hero / Moonscraper): je Abschnitt ein Aufklapper,
/// beim Oeffnen ALLE zugeklappt (Nutzervorgabe) -- die Zusammenfassung zeigt,
/// was drinsteckt. Ticks bekommen die Songzeit daneben, Noten ihre Bundfarbe.
public struct ChartPreviewRenderer: PreviewRenderer {

    /// Eigener Typ: macOS kennt `.chart` nicht und vergibt sonst nur einen
    /// dynamischen Typ, fuer den Quick Look keine Erweiterung fragt.
    public static let typeIdentifier = "io.celox.loupe.chart"

    /// Mehr Zeilen je Abschnitt werden nicht gezeichnet (die laengste Spur einer
    /// typischen Datei hat ~5 000 Noten; alles darueber macht Quick Look zaeh).
    public static let maxRowsPerSection = 5_000

    /// Hoechstens so viele Zeilen insgesamt (typische Charts haben 5 000–30 000).
    public static let maxRowsTotal = 30_000

    /// Von einer .chart hoechstens so viel lesen (typisch < 1 MB); danach der
    /// uebliche Hinweis „nur der Anfang wurde gelesen“.
    public static let maxReadBytes = 8 * 1024 * 1024

    public static var readStrategy: PreviewReadStrategy { .headAtMost(maxBytes: maxReadBytes) }

    public static let category: PreviewCategory = .chart

    public static var supportedTypes: [UTType] {
        [UTType(typeIdentifier)].compactMap { $0 }
    }

    public init() {}

    public func renderHTML(input: PreviewInput, settings: LoupeSettings) -> String {
        let text = PlainTextFallback.text(from: input.data)
        let doc = ChartParser.parse(text)
        let body = renderBody(document: doc, rawText: text,
                              filename: input.url.lastPathComponent,
                              totalBytes: input.data.count,
                              truncated: input.wasTruncatedByReader)
        return HTMLDocument.wrap(body: body,
                                 title: input.url.lastPathComponent,
                                 css: CSSGenerator.generateChartCSS(settings: settings),
                                 csp: HTMLDocument.contentSecurityPolicy)
    }

    public func renderBody(document doc: ChartDocument, rawText: String,
                           filename: String, totalBytes: Int, truncated: Bool) -> String {
        var html = "<div class=\"lp-code-container ch\">\n"
        html += toolbar(doc: doc, filename: filename, totalBytes: totalBytes)

        var notes: [String] = []
        if truncated {
            notes.append("Datei abgeschnitten — nur der Anfang wurde gelesen. Die Datei selbst ist in Ordnung.")
        }
        if !doc.isChart {
            notes.append("Keine Chart-Abschnitte erkannt — die Datei wird als Text gezeigt.")
        } else if !doc.problems.isEmpty {
            let shown = doc.problems.prefix(5).map { "Zeile \($0.line): \($0.message)" }
            var text = shown.joined(separator: " · ")
            if doc.problems.count > 5 { text += " · … und \(doc.problems.count - 5) weitere" }
            notes.append(text)
        }
        if !notes.isEmpty {
            html += "<div class=\"lp-banner lp-banner-notice\">\(HTMLEscape.escape(notes.joined(separator: " ")))</div>\n"
        }

        guard doc.isChart else {
            html += "<div class=\"lp-code-scroll\"><pre class=\"ch-raw\">\(HTMLEscape.escape(rawText))</pre></div>\n</div>\n"
            return html
        }

        let timing = ChartTiming(document: doc)
        html += "<div class=\"lp-code-scroll ch-body\">\n"
        var budget = Self.maxRowsTotal
        for section in doc.sections {
            html += renderSection(section, timing: timing, budget: &budget)
        }
        html += "</div>\n</div>\n"
        return html
    }

    // MARK: - Abschnitte

    private func renderSection(_ s: ChartSection, timing: ChartTiming, budget: inout Int) -> String {
        // Bewusst OHNE `open`: jeder Abschnitt startet zugeklappt.
        var html = "<details class=\"ch-sec\"><summary>"
        html += "<span class=\"ch-name\">[\(HTMLEscape.escape(s.name))]</span>"
        html += "<span class=\"ch-sum\">\(HTMLEscape.escape(summary(of: s)))</span>"
        html += "</summary>\n"
        if s.entries.isEmpty {
            html += "<div class=\"ch-empty\">Leerer Abschnitt</div>\n</details>\n"
            return html
        }
        let shown = min(s.entries.count, Self.maxRowsPerSection, budget)
        budget -= shown
        if shown > 0 {
            html += "<table class=\"ch-table\"><tbody>\n"
            for e in s.entries.prefix(shown) {
                html += row(e, timing: timing)
            }
            html += "</tbody></table>\n"
        }
        let omitted = s.entries.count - shown
        if omitted > 0 {
            html += "<div class=\"lp-omitted ch-omitted\">… \(omitted) weitere Einträge nicht dargestellt</div>\n"
        }
        html += "</details>\n"
        return html
    }

    /// „4 811 Einträge“ ist nichtssagend -- gezaehlt wird, was der Abschnitt enthaelt.
    func summary(of s: ChartSection) -> String {
        if s.entries.isEmpty { return "leer" }
        if s.entries.allSatisfy({ $0.tick == nil }) { return plural(s.entries.count, "Wert", "Werte") }
        if s.name == "SyncTrack" { return "\(s.entries.count) Tempo/Takt" }
        var parts: [String] = []
        var notes = 0, sp = 0, ev = 0
        for e in s.entries {
            switch e.kind {
            case "N": notes += 1
            case "S": sp += 1
            case "E": ev += 1
            default: break
            }
        }
        let other = s.entries.count - notes - sp - ev
        if notes > 0 { parts.append(plural(notes, "Note", "Noten")) }
        if sp > 0 { parts.append("\(sp) Star Power") }
        if ev > 0 { parts.append(plural(ev, "Ereignis", "Ereignisse")) }
        if other > 0 { parts.append(plural(other, "Eintrag", "Einträge")) }
        return parts.joined(separator: " · ")
    }

    private func plural(_ n: Int, _ one: String, _ many: String) -> String { "\(n) \(n == 1 ? one : many)" }

    // MARK: - Zeilen

    private func row(_ e: ChartEntry, timing: ChartTiming) -> String {
        guard let tick = e.tick else {
            return "<tr><td class=\"ch-key\">\(HTMLEscape.escape(e.key))</td>"
                + "<td class=\"ch-val\" colspan=\"3\">\(songValue(e))</td></tr>\n"
        }
        return "<tr><td class=\"ch-tick\">\(tick)</td>"
            + "<td class=\"ch-time\">\(ChartTiming.format(timing.seconds(at: tick)))</td>"
            + "<td class=\"ch-kind\"><span class=\"ch-badge ch-k-\(cssToken(e.kind))\">\(HTMLEscape.escape(e.kind))</span></td>"
            + "<td class=\"ch-val\">\(content(e))</td></tr>\n"
    }

    private func songValue(_ e: ChartEntry) -> String {
        let quoted = e.value.hasPrefix("\"") && e.value.hasSuffix("\"") && e.value.count >= 2
        if quoted { return "<span class=\"ch-str\">\(HTMLEscape.escape(e.text))</span>" }
        if Double(e.value) != nil { return "<span class=\"ch-num\">\(HTMLEscape.escape(e.value))</span>" }
        return HTMLEscape.escape(e.value)
    }

    private static let fretNames = ["Grün", "Rot", "Gelb", "Blau", "Orange"]
    private static let flagNames = [5: "Force", 6: "Tap", 7: "Open"]

    private func content(_ e: ChartEntry) -> String {
        switch e.kind {
        case "N":
            guard let fret = e.args.first.flatMap({ Int($0) }) else { return raw(e) }
            var out: String
            if fret >= 0, fret < Self.fretNames.count {
                out = "<span class=\"ch-fret ch-f\(fret)\">\(Self.fretNames[fret])</span>"
            } else if let flag = Self.flagNames[fret] {
                out = "<span class=\"ch-flag\">\(flag)</span>"
            } else {
                out = "<span class=\"ch-flag\">Bund \(fret)</span>"
            }
            return out + sustain(e.args.dropFirst().first)
        case "S":
            guard let type = e.args.first else { return raw(e) }
            let label = type == "2" ? "Star Power" : "Phrase \(HTMLEscape.escape(type))"
            return "<span class=\"ch-sp\">\(label)</span>" + sustain(e.args.dropFirst().first)
        case "E":
            let t = e.text
            if t.hasPrefix("section ") {
                return "<span class=\"ch-ev ch-section\">\(HTMLEscape.escape(t))</span>"
            }
            return "<span class=\"ch-ev\">\(HTMLEscape.escape(t))</span>"
        case "B":
            guard let milli = e.args.first.flatMap({ Double($0) }) else { return raw(e) }
            return "<span class=\"ch-sync\">\(Self.bpm(milli / 1000)) BPM</span>"
        case "TS":
            guard let num = e.args.first.flatMap({ Int($0) }) else { return raw(e) }
            let exp = e.args.dropFirst().first.flatMap { Int($0) } ?? 2
            let den = (0...6).contains(exp) ? 1 << exp : 4
            return "<span class=\"ch-sync\">\(num)/\(den)</span>"
        default:
            return raw(e)
        }
    }

    private func sustain(_ arg: String?) -> String {
        guard let s = arg.flatMap({ Int($0) }), s > 0 else { return "" }
        return " <span class=\"ch-sus\">↦ \(s)</span>"
    }

    private func raw(_ e: ChartEntry) -> String {
        "<span class=\"ch-rawval\">\(HTMLEscape.escape(e.args.joined(separator: " ")))</span>"
    }

    /// 120 → "120", 175,336 → "175,336" (deutsches Komma wie der uebrige Rahmen).
    static func bpm(_ value: Double) -> String {
        var s = String(format: "%.3f", value)
        while s.hasSuffix("0") { s.removeLast() }
        if s.hasSuffix(".") { s.removeLast() }
        return s.replacingOccurrences(of: ".", with: ",")
    }

    private func cssToken(_ s: String) -> String {
        let t = s.filter { $0.isLetter || $0.isNumber }
        return t.isEmpty ? "x" : t
    }

    private func toolbar(doc: ChartDocument, filename: String, totalBytes: Int) -> String {
        var left = "<span class=\"lp-filename\">\(HTMLEscape.escape(filename))</span><span class=\"lp-badge\">CHART</span>"
        let title = [doc.songValue("Artist"), doc.songValue("Name")].compactMap { $0 }.filter { !$0.isEmpty }
        if !title.isEmpty {
            left += "<span class=\"ch-title\">\(HTMLEscape.escape(title.joined(separator: " – ")))</span>"
        }
        var right = ""
        if doc.isChart { right += "<span>\(plural(doc.sections.count, "Abschnitt", "Abschnitte"))</span>" }
        right += "<span>\(plural(doc.totalLines, "Zeile", "Zeilen"))</span>"
        right += "<span>\(formatSize(totalBytes))</span>"
        return """
        <div class="lp-toolbar">
            <div class="lp-toolbar-left">\(left)</div>
            <div class="lp-toolbar-right">\(right)</div>
        </div>

        """
    }

    private func formatSize(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }
}
