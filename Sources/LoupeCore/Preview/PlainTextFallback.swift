import Foundation

/// Rohtext fuer den abgeschalteten Zustand. Quick Look faellt bei einer Absage
/// der Erweiterung NICHT auf den Text-Generator von macOS zurueck, sondern zeigt
/// nur die Datei-Karte. Loupe reicht darum den Inhalt als `public.plain-text`
/// durch -- Quick Look stellt ihn dann selbst dar, wie ohne Loupe.
public enum PlainTextFallback {
    public static func text(from data: Data) -> String {
        if data.isEmpty { return "" }
        let bytes = [UInt8](data.prefix(3))
        // UTF-8-BOM selbst entfernen: ob Foundation das tut, haengt von der
        // macOS-Version ab (neu: ja, macOS 14 auf der CI: nein).
        if bytes.count >= 3, bytes[0] == 0xEF, bytes[1] == 0xBB, bytes[2] == 0xBF {
            return text(from: data.dropFirst(3))
        }
        if bytes.count >= 2, bytes[0] == 0xFF, bytes[1] == 0xFE {
            return String(data: data.dropFirst(2), encoding: .utf16LittleEndian) ?? ""
        }
        if bytes.count >= 2, bytes[0] == 0xFE, bytes[1] == 0xFF {
            return String(data: data.dropFirst(2), encoding: .utf16BigEndian) ?? ""
        }
        if let s = String(data: data, encoding: .utf8) { return s }
        // Am Leseende halb abgeschnittenes Zeichen: NUR eine unvollstaendige
        // UTF-8-Folge am Ende entfernen, sonst waere Latin-1-Text verstuemmelt.
        let incomplete = incompleteUTF8Tail(data)
        if incomplete > 0, let s = String(data: data.dropLast(incomplete), encoding: .utf8) { return s }
        // Kein UTF-8: Latin-1 bildet jedes Byte ab, nichts geht verloren.
        return String(data: data, encoding: .isoLatin1) ?? ""
    }

    /// Laenge einer am Ende angefangenen, aber unvollstaendigen UTF-8-Folge (0 = keine).
    static func incompleteUTF8Tail(_ data: Data) -> Int {
        let tail = [UInt8](data.suffix(3))
        for back in 1...tail.count {
            let b = tail[tail.count - back]
            if b & 0xC0 == 0x80 { continue }          // Folgebyte
            let need = b & 0xE0 == 0xC0 ? 2 : b & 0xF0 == 0xE0 ? 3 : b & 0xF8 == 0xF0 ? 4 : 1
            return need > back ? back : 0
        }
        return 0
    }
}
