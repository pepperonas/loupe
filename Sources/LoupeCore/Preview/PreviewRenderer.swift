import Foundation
import UniformTypeIdentifiers

/// Alles, was ein Renderer über die anzuzeigende Datei wissen muss.
public struct PreviewInput: Sendable {
    public let data: Data
    public let url: URL
    /// true, wenn der Leser bei der Byte-Grenze abgeschnitten hat.
    /// Ohne dieses Wissen meldet der Parser eine gültige Großdatei als kaputt.
    public let wasTruncatedByReader: Bool

    public init(data: Data, url: URL, wasTruncatedByReader: Bool) {
        self.data = data
        self.url = url
        self.wasTruncatedByReader = wasTruncatedByReader
    }
}

public protocol PreviewRenderer: Sendable {
    static var supportedTypes: [UTType] { get }
    func renderHTML(input: PreviewInput, settings: LoupeSettings) -> String
}
