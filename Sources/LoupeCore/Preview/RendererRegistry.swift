import Foundation
import UniformTypeIdentifiers

/// Die Naht fuer weitere Formate. Markdown wird spaeter EIN Eintrag mehr.
public enum RendererRegistry {
    private static let all: [any PreviewRenderer] = [
        JSONPreviewRenderer()
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
}
