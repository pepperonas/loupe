import Foundation
import UniformTypeIdentifiers

public struct CSVPreviewRenderer: PreviewRenderer {
    public static var supportedTypes: [UTType] {
        var types: [UTType] = [
            .commaSeparatedText,
            .tabSeparatedText,
            .delimitedText
        ]
        if let csv = UTType("public.comma-separated-values-text"), !types.contains(csv) {
            types.append(csv)
        }
        if let tsv = UTType("public.tab-separated-values-text"), !types.contains(tsv) {
            types.append(tsv)
        }
        if let delimited = UTType("public.delimited-values-text"), !types.contains(delimited) {
            types.append(delimited)
        }
        if let tagCsv = UTType(filenameExtension: "csv"), !types.contains(tagCsv) {
            types.append(tagCsv)
        }
        if let tagTsv = UTType(filenameExtension: "tsv"), !types.contains(tagTsv) {
            types.append(tagTsv)
        }
        return types
    }

    public init() {}

    public func renderHTML(input: PreviewInput, settings: LoupeSettings) -> String {
        let text = String(decoding: input.data, as: UTF8.self)
        let preferredDelim: Character? = input.url.pathExtension.lowercased() == "tsv" ? "\t" : nil
        let parser = CSVParser(preferredDelimiter: preferredDelim)
        let document = parser.parse(text: text, wasTruncatedByReader: input.wasTruncatedByReader)
        let tableRenderer = CSVTableRenderer(settings: settings)
        let body = tableRenderer.renderBody(document: document)
        let css = CSSGenerator.generateCSVCSS(settings: settings)
        return HTMLDocument.wrap(
            body: body,
            title: input.url.lastPathComponent,
            css: css,
            csp: HTMLDocument.contentSecurityPolicy
        )
    }
}
