import Foundation
import QuickLookUI
import UniformTypeIdentifiers
import LoupeCore

@objc(PreviewProvider)
public final class PreviewProvider: QLPreviewProvider, QLPreviewingController {

    private static let maxBytes = ParseLimits().maxBytes

    public override init() { super.init() }

    public func providePreview(
        for request: QLFilePreviewRequest,
        completionHandler: @escaping (QLPreviewReply?, (any Error)?) -> Void
    ) {
        let url = request.fileURL
        let settings = LoupeSettings.load()

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let size = (attributes[.size] as? Int) ?? 0

            let data: Data
            let truncated: Bool
            if size > Self.maxBytes {
                // Nur den Anfang lesen -- und dem Parser SAGEN, dass wir
                // gekuerzt haben, sonst meldet er die Datei als kaputt.
                let handle = try FileHandle(forReadingFrom: url)
                defer { try? handle.close() }
                data = handle.readData(ofLength: Self.maxBytes)
                truncated = true
            } else {
                data = try Data(contentsOf: url)
                truncated = false
            }

            let renderer = RendererRegistry.renderer(for: url)
                ?? ((try? url.resourceValues(forKeys: [.contentTypeKey]).contentType).flatMap { RendererRegistry.renderer(for: $0) })
                ?? RendererRegistry.renderer(for: .json)
            guard let renderer else {
                completionHandler(nil, CocoaError(.fileReadUnsupportedScheme))
                return
            }

            let input = PreviewInput(data: data, url: url, wasTruncatedByReader: truncated)
            let html = renderer.renderHTML(input: input, settings: settings)

            let reply = QLPreviewReply(dataOfContentType: .html,
                                       contentSize: CGSize(width: 840, height: 640)) { _ in
                html.data(using: .utf8) ?? Data()
            }
            reply.title = url.lastPathComponent
            completionHandler(reply, nil)
        } catch {
            let body = """
            <div class="lp-banner lp-banner-error">Die Datei konnte nicht gelesen werden: \
            \(HTMLEscape.escape(error.localizedDescription))</div>
            """
            let html = HTMLDocument.wrap(body: body,
                                         title: url.lastPathComponent,
                                         css: CSSGenerator.generateCSS(settings: settings))
            let reply = QLPreviewReply(dataOfContentType: .html,
                                       contentSize: CGSize(width: 520, height: 300)) { _ in
                html.data(using: .utf8) ?? Data()
            }
            completionHandler(reply, nil)
        }
    }
}
