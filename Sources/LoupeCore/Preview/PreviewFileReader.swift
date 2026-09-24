import Foundation

/// Liest den für die Vorschau nötigen Teil einer Datei, ohne große Dateien
/// komplett in den Speicher zu holen.
public enum PreviewFileReader {
    public struct Result: Sendable {
        public let data: Data
        /// Am Ende abgeschnitten (Head-Lesen über der Grenze).
        public let truncatedAtEnd: Bool
        /// Am Anfang übersprungen (Tail-Lesen).
        public let skippedBytesAtStart: Int
        /// Zeilenumbrüche im übersprungenen Teil -- damit die Zeilennummern
        /// absolut bleiben. nil, wenn der Teil zu groß zum Zählen war.
        public var skippedLineBreaks: Int? = nil
    }

    /// Bis zu dieser Größe wird der übersprungene Teil gezählt (reines Byte-Zählen, schnell).
    public static let maxCountedBytes = 512 * 1024 * 1024

    public static func read(url: URL, strategy: PreviewReadStrategy, headLimit: Int) throws -> Result {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attributes[.size] as? NSNumber)?.intValue ?? 0

        switch strategy {
        case .head:
            guard size > headLimit else {
                return Result(data: try Data(contentsOf: url), truncatedAtEnd: false, skippedBytesAtStart: 0)
            }
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            let data = try handle.read(upToCount: headLimit) ?? Data()
            return Result(data: data, truncatedAtEnd: true, skippedBytesAtStart: 0)

        case .tail(let maxBytes):
            guard size > maxBytes else {
                return Result(data: try Data(contentsOf: url), truncatedAtEnd: false, skippedBytesAtStart: 0)
            }
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            let offset = size - maxBytes
            try handle.seek(toOffset: UInt64(offset))
            let data = try handle.readToEnd() ?? Data()
            var result = Result(data: data, truncatedAtEnd: false, skippedBytesAtStart: offset)
            if offset <= maxCountedBytes {
                try handle.seek(toOffset: 0)
                result.skippedLineBreaks = try countLineBreaks(handle, upTo: offset)
            }
            return result
        }
    }

    private static func countLineBreaks(_ handle: FileHandle, upTo limit: Int) throws -> Int {
        var remaining = limit
        var count = 0
        while remaining > 0 {
            guard let chunk = try handle.read(upToCount: min(remaining, 1 << 20)), !chunk.isEmpty else { break }
            remaining -= chunk.count
            chunk.withUnsafeBytes { raw in
                for byte in raw where byte == 0x0A { count += 1 }
            }
        }
        return count
    }
}
