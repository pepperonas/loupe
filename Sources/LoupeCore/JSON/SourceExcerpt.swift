import Foundation

public struct ExcerptLine: Equatable, Sendable {
    public let number: Int
    public let text: String
    /// 1-basierte Spalte im BEREITS geklippten Text, oder nil.
    public let caretColumn: Int?
}

public enum SourceExcerpt {
    /// Maximale Breite einer Ausschnittszeile. Minifiziertes JSON ist eine
    /// einzige Zeile mit Millionen Zeichen -- ungeklippt unbrauchbar.
    public static let maxLineWidth = 200

    /// Darstellungsbreite eines Tabulators.
    public static let tabWidth = 4

    public static func make(bytes: [UInt8],
                            around position: Position,
                            contextLines: Int = 1) -> [ExcerptLine] {
        let all = String(decoding: bytes, as: UTF8.self)
            .split(separator: "\n", omittingEmptySubsequences: false)
        guard !all.isEmpty else { return [] }

        let first = max(1, position.line - contextLines)
        let last  = min(all.count, position.line + contextLines)
        guard first <= last else { return [] }

        return (first ... last).map { number in
            let original = String(all[number - 1])
            let isCaretLine = number == position.line

            // ⚠️ ZWEI Umrechnungen, beide notwendig (Feldbefund 2026-09-22 --
            // eine fruehere Fassung hatte keine davon und setzte den Zeiger
            // bei "grüße" hinter das Zeilenende):
            //
            // (1) Die Lexer-Spalte zaehlt BYTES in der Zeile
            //     (JSONLexer: `column = index - lineStart + 1`), Swift indiziert
            //     Strings nach CHARACTERS. Jedes Mehrbyte-Zeichen davor -- ein
            //     Umlaut, ein Emoji, kyrillischer Text -- verschiebt den Zeiger.
            let caretCharColumn: Int
            if isCaretLine {
                let davor = original.utf8.prefix(max(0, position.column - 1))
                caretCharColumn = String(decoding: davor, as: UTF8.self).count + 1
            } else {
                caretCharColumn = 1
            }

            // (2) Die Tab-Ersetzung VERBREITERT den Text. Die Spalte muss um
            //     dieselbe Verbreiterung nachgezogen werden, sonst zeigt der
            //     Zeiger auf ein Leerzeichen der Expansion.
            let tabsDavor = original.prefix(max(0, caretCharColumn - 1))
                .filter { $0 == "\t" }.count
            let raw = original.replacingOccurrences(
                of: "\t", with: String(repeating: " ", count: tabWidth))
            let centre = isCaretLine
                ? caretCharColumn + tabsDavor * (tabWidth - 1)
                : 1

            guard raw.count > maxLineWidth else {
                return ExcerptLine(number: number, text: raw,
                                   caretColumn: isCaretLine ? min(centre, raw.count + 1) : nil)
            }
            // Fenster um die Fehlerstelle legen, nicht stumpf vorne abschneiden.
            let start = max(0, min(centre - maxLineWidth / 2, raw.count - maxLineWidth))
            let clipped = String(raw.dropFirst(start).prefix(maxLineWidth))
            let prefix = start > 0 ? "…" : ""
            return ExcerptLine(number: number,
                               text: prefix + clipped,
                               caretColumn: isCaretLine
                                   ? max(1, centre - start + prefix.count)
                                   : nil)
        }
    }
}
