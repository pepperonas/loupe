import Foundation

/// Eine Zeile `schluessel = wert` innerhalb eines Abschnitts.
public struct ChartEntry: Equatable, Sendable {
    public let line: Int
    public let key: String
    /// Rechte Seite, unveraendert (ohne umgebende Leerzeichen).
    public let value: String
    /// Der Schluessel als Tick, wenn er eine Zahl ist (Spuren, SyncTrack, Events).
    /// Einmal beim Lesen bestimmt -- Renderer und Zusammenfassung fragen ihn oft ab.
    public let tick: Int?
    /// Erstes Wort des Werts: N, S, E, B, TS, A …
    public let kind: String
    /// Die uebrigen Woerter des Werts (bei E ungenutzt, siehe `text`).
    public let args: [String]
    /// Der Text eines Ereignisses (E) bzw. eines Song-Werts, ohne Anfuehrungszeichen.
    public let text: String
}

public struct ChartSection: Equatable, Sendable {
    public let name: String
    public let line: Int
    public var entries: [ChartEntry]
}

public struct ChartProblem: Equatable, Sendable {
    public let line: Int
    public let message: String
}

public struct ChartDocument: Equatable, Sendable {
    public var sections: [ChartSection]
    public var problems: [ChartProblem]
    public let totalLines: Int

    public var isChart: Bool { !sections.isEmpty }

    /// Wert aus `[Song]`, Anfuehrungszeichen entfernt.
    public func songValue(_ key: String) -> String? {
        sections.first { $0.name == "Song" }?.entries.first { $0.key == key }?.text
    }
}

/// Liest das `.chart`-Format (Clone Hero / Moonscraper):
///
///     [Abschnitt]
///     {
///       schluessel = wert
///     }
///
/// Robust statt streng: eine kaputte Zeile wird als Problem gemeldet und
/// uebersprungen, der Rest der Datei bleibt sichtbar.
public enum ChartParser {
    public static func parse(_ raw: String) -> ChartDocument {
        let text = raw.hasPrefix("\u{FEFF}") ? String(raw.dropFirst()) : raw
        // Auf BYTE-Ebene an \n trennen: Characters zerlegen ist graphembewusst und bei
        // 5 MB der teuerste Schritt. Ein \r davor (CRLF) wird abgeschnitten.
        var lines: [Substring] = text.utf8.split(separator: 10, omittingEmptySubsequences: false).map { raw in
            var line = raw
            if line.last == 13 { line = line.dropLast() }
            return Substring(line)
        }
        if lines.count > 1, lines.last?.isEmpty == true { lines.removeLast() }

        var sections: [ChartSection] = []
        var problems: [ChartProblem] = []
        var current: ChartSection?
        var inBody = false

        func close() {
            if let c = current { sections.append(c) }
            current = nil
            inBody = false
        }

        for (i, sub) in lines.enumerated() {
            let n = i + 1
            let t = trimmed(sub)
            if t.isEmpty { continue }

            if t.utf8.first == 91, t.utf8.last == 93, t.utf8.count >= 2 {   // [ … ]
                if current != nil, inBody {
                    problems.append(ChartProblem(line: n, message: "Abschnitt \"\(current!.name)\" ohne schließende }"))
                }
                close()
                current = ChartSection(name: String(t.dropFirst().dropLast()), line: n, entries: [])
                continue
            }
            if t == "{" {
                if current == nil || inBody {
                    problems.append(ChartProblem(line: n, message: "{ ohne vorangehenden Abschnitt"))
                } else {
                    inBody = true
                }
                continue
            }
            if t == "}" {
                if current == nil || !inBody {
                    problems.append(ChartProblem(line: n, message: "} ohne offenen Abschnitt"))
                } else {
                    close()
                }
                continue
            }
            guard current != nil, inBody else {
                problems.append(ChartProblem(line: n, message: "Zeile außerhalb eines Abschnitts"))
                continue
            }
            guard let eq = t.utf8.firstIndex(of: 61) else {   // "="
                problems.append(ChartProblem(line: n, message: "Zeile ohne \"=\""))
                continue
            }
            let key = String(trimmed(t[..<eq]))
            let value = String(trimmed(t[t.index(after: eq)...]))
            guard !key.isEmpty else {
                problems.append(ChartProblem(line: n, message: "Zeile ohne Schlüssel"))
                continue
            }
            current!.entries.append(makeEntry(line: n, key: key, value: value))
        }
        if let c = current, inBody {
            problems.append(ChartProblem(line: lines.count, message: "Abschnitt \"\(c.name)\" ohne schließende }"))
        }
        close()
        return ChartDocument(sections: sections, problems: problems, totalLines: lines.count)
    }

    private static func makeEntry(line: Int, key: String, value: String) -> ChartEntry {
        // Bytes statt Characters: das Wort-Zerlegen war der groesste Posten beim Lesen.
        let words = value.utf8.split(separator: 32, omittingEmptySubsequences: true).map { String(Substring($0)) }
        let kind = words.first ?? ""
        let tick = Int(key)
        // Song-Werte ("Name = \"X\"") tragen den Text im ganzen Wert, Ereignisse (E "x") im Rest.
        let text: String
        if tick == nil {
            text = unquote(value)
        } else if kind == "E" {
            text = unquote(String(trimmed(value.dropFirst(kind.count))))
        } else {
            text = ""   // Noten, Tempo usw. tragen keinen Text -- spart 280 000 Kopien bei 5 MB
        }
        return ChartEntry(line: line, key: key, value: value, tick: tick, kind: kind,
                          args: Array(words.dropFirst()), text: text)
    }

    /// Leerzeichen und Tabs an beiden Enden weg -- ohne Foundation (die war hier der Engpass).
    static func trimmed(_ s: Substring) -> Substring {
        let u = s.utf8
        var start = u.startIndex, end = u.endIndex
        while start < end, u[start] == 32 || u[start] == 9 { start = u.index(after: start) }
        while end > start {
            let before = u.index(before: end)
            guard u[before] == 32 || u[before] == 9 else { break }
            end = before
        }
        return s[start..<end]
    }

    static func trimmed(_ s: String) -> Substring { trimmed(s[...]) }

    static func unquote(_ s: String) -> String {
        if s.count >= 2, s.hasPrefix("\""), s.hasSuffix("\"") { return String(s.dropFirst().dropLast()) }
        return s
    }
}

/// Rechnet Ticks in Sekunden um -- ueber `Resolution` (Ticks je Viertel) und
/// die Tempowechsel `B` aus `[SyncTrack]` (Tausendstel BPM).
public struct ChartTiming: Sendable {
    public let resolution: Int
    /// (Tick, BPM) aufsteigend, beginnt immer bei Tick 0.
    private let tempos: [(tick: Int, bpm: Double)]
    /// Sekunden am Anfang jedes Tempo-Abschnitts (gleiche Reihenfolge wie `tempos`).
    private let starts: [Double]

    public init(document: ChartDocument) {
        let res = document.songValue("Resolution").flatMap { Int($0) }.flatMap { $0 > 0 ? $0 : nil } ?? 192
        resolution = res
        var list: [(Int, Double)] = []
        for e in document.sections.first(where: { $0.name == "SyncTrack" })?.entries ?? [] where e.kind == "B" {
            if let tick = e.tick, let milli = e.args.first.flatMap({ Double($0) }), milli > 0 {
                list.append((tick, milli / 1000))
            }
        }
        list.sort { $0.0 < $1.0 }
        if list.first?.0 != 0 { list.insert((0, list.first?.1 ?? 120), at: 0) }
        var merged: [(tick: Int, bpm: Double)] = []
        for (t, b) in list {                   // gleicher Tick: der spaetere Wert gilt
            if merged.last?.tick == t { merged[merged.count - 1].bpm = b } else { merged.append((t, b)) }
        }
        tempos = merged
        var acc = 0.0
        var s: [Double] = []
        for (i, seg) in merged.enumerated() {
            s.append(acc)
            if i + 1 < merged.count {
                acc += Double(merged[i + 1].tick - seg.tick) / Double(res) * 60 / seg.bpm
            }
        }
        starts = s
    }

    public func seconds(at tick: Int) -> Double {
        // Letzter Abschnitt, der vor oder am Tick beginnt (binaere Suche -- Spuren haben Tausende Noten).
        var lo = 0, hi = tempos.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if tempos[mid].tick <= tick { lo = mid } else { hi = mid - 1 }
        }
        let seg = tempos[lo]
        return starts[lo] + Double(tick - seg.tick) / Double(resolution) * 60 / seg.bpm
    }

    /// `m:ss.mmm`
    public static func format(_ seconds: Double) -> String {
        let ms = Int((max(0, seconds) * 1000).rounded())
        // Von Hand statt String(format:) -- das war bei 45 000 Zeilen die Haelfte der Zeichenzeit.
        let sec = (ms / 1000) % 60, milli = ms % 1000
        return "\(ms / 60000):" + (sec < 10 ? "0" : "") + "\(sec)."
            + (milli < 100 ? (milli < 10 ? "00" : "0") : "") + "\(milli)"
    }
}
