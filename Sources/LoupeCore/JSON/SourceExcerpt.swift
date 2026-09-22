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
            // Tabs vor dem Klippen ersetzen, sonst verschiebt sich der Zeiger.
            let raw = String(all[number - 1]).replacingOccurrences(of: "\t", with: "    ")
            let isCaretLine = number == position.line
            guard raw.count > maxLineWidth else {
                return ExcerptLine(number: number, text: raw,
                                   caretColumn: isCaretLine ? min(position.column, raw.count + 1) : nil)
            }
            // Fenster um die Fehlerstelle legen, nicht stumpf vorne abschneiden.
            let centre = isCaretLine ? position.column : 1
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
