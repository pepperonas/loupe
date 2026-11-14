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
            // Gleiche Pipeline wie das Dokumentfenster der App (PreviewPipeline in LoupeCore)
            switch try PreviewPipeline.render(url: url, settings: settings, maxBytes: Self.maxBytes) {
            case .html(let html):
                logger.notice("Rendered HTML (\(html.utf8.count) bytes) for \(url.lastPathComponent, privacy: .public)")
                let reply = QLPreviewReply(dataOfContentType: .html,
                                           contentSize: CGSize(width: 840, height: 640)) { _ in
                    html.data(using: .utf8) ?? Data()
                }
                reply.title = url.lastPathComponent
                completionHandler(reply, nil)
            case .plainText(let text):
                // In der Companion-App abgeschaltet (global oder diese Rubrik):
                // Rohtext liefern, wie macOS ohne Loupe. Eine Absage (Fehler) liesse
                // Quick Look NICHT auf seinen Text-Generator zurueckfallen, sondern
                // nur die Datei-Karte zeigen.
                logger.notice("Preview disabled, plain text: \(url.lastPathComponent, privacy: .public)")
                let reply = QLPreviewReply(dataOfContentType: .plainText,
                                           contentSize: CGSize(width: 840, height: 640)) { r in
                    r.stringEncoding = .utf8
                    return Data(text.utf8)
                }
                reply.title = url.lastPathComponent
                completionHandler(reply, nil)
            case .unsupported:
                // Binaerformat abgeschaltet oder kein Renderer: eine Absage zeigt die Datei-Karte, wie ohne Loupe.
                logger.notice("No Loupe preview, file card: \(url.lastPathComponent, privacy: .public)")
                completionHandler(nil, CocoaError(.featureUnsupported))
            }
        } catch {
            logger.error("providePreview ERROR: \(error.localizedDescription, privacy: .public)")
            let html = PreviewPipeline.errorHTML(message: error.localizedDescription,
                                                 title: url.lastPathComponent, settings: settings)
            let reply = QLPreviewReply(dataOfContentType: .html,
                                       contentSize: CGSize(width: 520, height: 300)) { _ in
                html.data(using: .utf8) ?? Data()
            }
            completionHandler(reply, nil)
        }
    }
}
