import Foundation
import QuickLookUI
import UniformTypeIdentifiers
import LoupeCore
import os

private let logger = Logger(subsystem: "io.celox.loupe.preview", category: "Preview")

public final class PreviewProvider: QLPreviewProvider, QLPreviewingController {

    private static let maxBytes = ParseLimits().maxBytes

    public override init() { super.init() }

    public func providePreview(
        for request: QLFilePreviewRequest,
        completionHandler: @escaping (QLPreviewReply?, (any Error)?) -> Void
    ) {
        let url = request.fileURL
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        logger.notice("providePreview START: url=\(url.path, privacy: .public) (securityScoped=\(accessed))")

        let settings = LoupeSettings.load()

        do {
            let renderer = RendererRegistry.renderer(for: url)
                ?? ((try? url.resourceValues(forKeys: [.contentTypeKey]).contentType).flatMap { RendererRegistry.renderer(for: $0) })
                ?? RendererRegistry.renderer(for: .json)
            guard let renderer else {
                logger.error("No renderer found for url: \(url.path, privacy: .public)")
                completionHandler(nil, CocoaError(.fileReadUnsupportedScheme))
                return
            }

            // In der Companion-App abgeschaltet (global oder diese Rubrik):
            // Rohtext liefern, wie macOS ohne Loupe. Eine Absage (Fehler) liesse
            // Quick Look NICHT auf seinen Text-Generator zurueckfallen, sondern
            // nur die Datei-Karte zeigen.
            let category = type(of: renderer).category
            guard settings.isEnabled(category) else {
                logger.notice("Preview disabled for category \(category.rawValue, privacy: .public), plain text: \(url.lastPathComponent, privacy: .public)")
                let read = try PreviewFileReader.read(url: url, strategy: .head, headLimit: Self.maxBytes)
                let text = PlainTextFallback.text(from: read.data)
                let reply = QLPreviewReply(dataOfContentType: .plainText,
                                           contentSize: CGSize(width: 840, height: 640)) { r in
                    r.stringEncoding = .utf8
                    return Data(text.utf8)
                }
                reply.title = url.lastPathComponent
                completionHandler(reply, nil)
                return
            }

            // Der Renderer bestimmt, welcher Teil gelesen wird: Logs brauchen das
            // ENDE (dort steht das Neueste), alles andere den Anfang.
            let read = try PreviewFileReader.read(url: url,
                                                  strategy: type(of: renderer).readStrategy,
                                                  headLimit: Self.maxBytes)

            let rendererName = String(describing: type(of: renderer))
            logger.notice("Renderer selected: \(rendererName, privacy: .public) for file: \(url.lastPathComponent, privacy: .public)")

            let input = PreviewInput(data: read.data, url: url,
                                     wasTruncatedByReader: read.truncatedAtEnd,
                                     skippedBytesAtStart: read.skippedBytesAtStart,
                                     skippedLineBreaks: read.skippedLineBreaks)
            let html = renderer.renderHTML(input: input, settings: settings)

            logger.notice("Rendered HTML (\(html.utf8.count) bytes) for \(url.lastPathComponent, privacy: .public)")

            let reply = QLPreviewReply(dataOfContentType: .html,
                                       contentSize: CGSize(width: 840, height: 640)) { _ in
                html.data(using: .utf8) ?? Data()
            }
            reply.title = url.lastPathComponent
            completionHandler(reply, nil)
        } catch {
            logger.error("providePreview ERROR: \(error.localizedDescription, privacy: .public)")
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
