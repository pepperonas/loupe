import Foundation
import UniformTypeIdentifiers

public struct MarkdownPreviewRenderer: PreviewRenderer {
    public static var supportedTypes: [UTType] {
        var types: [UTType] = []
        if let md = UTType("net.daringfireball.markdown") { types.append(md) }
        if let pubMd = UTType("public.markdown") { types.append(pubMd) }
        if let tagMd = UTType(filenameExtension: "md") {
            if !types.contains(tagMd) { types.append(tagMd) }
        }
        return types
    }

    public init() {}

    public func renderHTML(input: PreviewInput, settings: LoupeSettings) -> String {
        let markdown = String(decoding: input.data, as: UTF8.self)
        let renderer = MarkdownRenderer(settings: settings, documentURL: input.url)
        return renderer.renderHTML(markdown: markdown, documentTitle: input.url.lastPathComponent)
    }
}
