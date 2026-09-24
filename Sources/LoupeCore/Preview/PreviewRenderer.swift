import Foundation
import UniformTypeIdentifiers

/// Alles, was ein Renderer über die anzuzeigende Datei wissen muss.
public struct PreviewInput: Sendable {
    public let data: Data
    public let url: URL
    /// true, wenn der Leser bei der Byte-Grenze abgeschnitten hat.
    /// Ohne dieses Wissen meldet der Parser eine gültige Großdatei als kaputt.
    public let wasTruncatedByReader: Bool
    /// Bytes am Dateianfang, die beim Tail-Lesen übersprungen wurden (0 = ab Anfang gelesen).
    public let skippedBytesAtStart: Int
    /// Zeilenumbrüche im übersprungenen Teil (nil = unbekannt).
    public let skippedLineBreaks: Int?

    public init(data: Data, url: URL, wasTruncatedByReader: Bool,
                skippedBytesAtStart: Int = 0, skippedLineBreaks: Int? = nil) {
        self.data = data
        self.url = url
        self.wasTruncatedByReader = wasTruncatedByReader
        self.skippedBytesAtStart = skippedBytesAtStart
        self.skippedLineBreaks = skippedLineBreaks
    }
}

/// Welcher Teil einer großen Datei gelesen wird.
public enum PreviewReadStrategy: Equatable, Sendable {
    /// Vom Anfang bis zur Byte-Grenze (Dokumente, Code).
    case head
    /// Nur die letzten `maxBytes` (Logs: das Neueste steht am Ende).
    case tail(maxBytes: Int)
}

public protocol PreviewRenderer: Sendable {
    static var supportedTypes: [UTType] { get }
    static var readStrategy: PreviewReadStrategy { get }
    func renderHTML(input: PreviewInput, settings: LoupeSettings) -> String
}

public extension PreviewRenderer {
    static var readStrategy: PreviewReadStrategy { .head }
}
