import Foundation

/// Ein DER-Element: Tag, Inhalt und die Bytes des ganzen Elements (Kopf + Inhalt).
struct DERNode {
    let tag: UInt8
    let content: ArraySlice<UInt8>
    let whole: ArraySlice<UInt8>

    var isConstructed: Bool { tag & 0x20 != 0 }

    /// Kinder eines zusammengesetzten Elements; leer bei kaputter Struktur.
    var children: [DERNode] { DERReader.nodes(in: content) }

    /// Inhalt als Zeichenkette -- fuer die in Zertifikaten ueblichen Texttypen.
    var string: String? {
        switch tag {
        case 0x1E:  // BMPString: UTF-16 BE
            return String(data: Data(content), encoding: .utf16BigEndian)
        case 0x14, 0x16, 0x13, 0x0C, 0x1A, 0x12:  // T61, IA5, Printable, UTF8, Visible, Numeric
            return String(data: Data(content), encoding: .utf8)
                ?? String(data: Data(content), encoding: .isoLatin1)
        default:
            return nil
        }
    }

    /// Objektkennung als Punktschreibweise ("2.5.4.3").
    var oid: String? {
        guard tag == 0x06, let first = content.first else { return nil }
        var parts: [UInt64] = [UInt64(first / 40), UInt64(first % 40)]
        var value: UInt64 = 0
        for byte in content.dropFirst() {
            // Mehr als 9 Bytes je Teil gibt es in echten OIDs nicht -- Ueberlauf abfangen.
            guard value >> 57 == 0 else { return nil }
            value = (value << 7) | UInt64(byte & 0x7F)
            if byte & 0x80 == 0 { parts.append(value); value = 0 }
        }
        return parts.map(String.init).joined(separator: ".")
    }
}

/// Liest DER mit festen Laengen. Alles ist grenzgeprueft: ein Keystore ist eine
/// fremde Binaerdatei, und die Vorschau darf an keiner Stelle abstuerzen.
enum DERReader {
    /// Hoechstens so tief wird eine Struktur verfolgt (Schutz vor boesartiger Schachtelung).
    static let maxNodes = 20_000

    static func nodes(in bytes: ArraySlice<UInt8>) -> [DERNode] {
        var result: [DERNode] = []
        var index = bytes.startIndex
        while index < bytes.endIndex, result.count < maxNodes {
            guard let node = node(in: bytes, at: &index) else { break }
            result.append(node)
        }
        return result
    }

    static func first(in bytes: ArraySlice<UInt8>) -> DERNode? {
        var index = bytes.startIndex
        return node(in: bytes, at: &index)
    }

    private static func node(in bytes: ArraySlice<UInt8>, at index: inout Int) -> DERNode? {
        let start = index
        guard index < bytes.endIndex else { return nil }
        let tag = bytes[index]
        index += 1
        // Mehrbyte-Tags kommen in Zertifikaten und PKCS #12 nicht vor.
        guard tag & 0x1F != 0x1F, index < bytes.endIndex else { return nil }
        let lengthByte = bytes[index]
        index += 1
        var length = 0
        if lengthByte & 0x80 == 0 {
            length = Int(lengthByte)
        } else {
            let count = Int(lengthByte & 0x7F)
            // 0 = unbestimmte Laenge (BER); mehr als 4 Bytes waere > 4 GB.
            guard count >= 1, count <= 4, bytes.endIndex - index >= count else { return nil }
            for _ in 0..<count {
                length = (length << 8) | Int(bytes[index])
                index += 1
            }
        }
        guard length >= 0, bytes.endIndex - index >= length else { return nil }
        let content = bytes[index..<(index + length)]
        index += length
        return DERNode(tag: tag, content: content, whole: bytes[start..<index])
    }
}
