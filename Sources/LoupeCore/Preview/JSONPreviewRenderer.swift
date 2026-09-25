import Foundation
import UniformTypeIdentifiers

public struct JSONPreviewRenderer: PreviewRenderer {
    public static let category: PreviewCategory = .json

    public static var supportedTypes: [UTType] { [.json] }

    public init() {}

    public func renderHTML(input: PreviewInput, settings: LoupeSettings) -> String {
        let bytes = [UInt8](input.data)
        var parser = JSONParser(bytes: bytes,
                                limits: ParseLimits(),
                                wasTruncatedByReader: input.wasTruncatedByReader)
        let result = parser.parse()

        let openPaths = result.root.map {
            ExpansionPolicy.plan(root: $0, budget: settings.expansionLineBudget)
        } ?? []

        let body = JSONTreeRenderer(settings: settings, openPaths: openPaths)
            .renderBody(result, sourceBytes: bytes)

        return HTMLDocument.wrap(body: body,
                                 title: input.url.lastPathComponent,
                                 css: CSSGenerator.generateCSS(settings: settings))
    }
}
