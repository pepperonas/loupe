import Foundation
import UniformTypeIdentifiers

/// Die Naht fuer unterstuetzte Vorschau-Formate (JSON, Markdown, und spaetere Erweiterungen).
public enum RendererRegistry {
    private static let all: [any PreviewRenderer] = [
        JSONPreviewRenderer(),
        MarkdownPreviewRenderer(),
        CSVPreviewRenderer(),
        LogPreviewRenderer(),
        SourceCodePreviewRenderer()
    ]

    public static func renderer(for type: UTType) -> (any PreviewRenderer)? {
        all.first { candidate in
            Swift.type(of: candidate).supportedTypes.contains {
                // Gleichheit ZUERST: ob conforms(to:) einen Typ als zu sich
                // selbst konform meldet, ist eine Annahme ueber Apples
                // Implementierung -- die Gleichheit ist es nicht.
                type == $0 || type.conforms(to: $0)
            }
        }
    }

    public static func renderer(for url: URL) -> (any PreviewRenderer)? {
        let ext = url.pathExtension.lowercased()
        let filename = url.lastPathComponent.lowercased()
        if SourceCodePreviewRenderer.supportedExtensions.contains(ext) ||
           SourceCodePreviewRenderer.supportedExtensions.contains(filename) {
            return SourceCodePreviewRenderer()
        }
        if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType,
           let r = renderer(for: type) {
            return r
        }
        if let extType = UTType(filenameExtension: url.pathExtension),
           let r = renderer(for: extType) {
            return r
        }
        return nil
    }
}
