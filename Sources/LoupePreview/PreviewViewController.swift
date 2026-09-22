import Cocoa
import QuickLookUI
import WebKit
import UniformTypeIdentifiers
import LoupeCore
import os

private let logger = Logger(subsystem: "io.celox.loupe.preview", category: "Preview")
private let maxBytes = ParseLimits().maxBytes

@objc(PreviewViewController)
public final class PreviewViewController: NSViewController, @preconcurrency QLPreviewingController {

    private var webView: WKWebView!

    public override func loadView() {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 840, height: 640), configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        self.view = webView
        self.preferredContentSize = NSSize(width: 840, height: 640)
    }

    public func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        logger.notice("preparePreviewOfFile START: url=\(url.path, privacy: .public) (securityScoped=\(accessed))")

        let settings = LoupeSettings.load()

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let size = (attributes[.size] as? Int) ?? 0

            let data: Data
            let truncated: Bool
            if size > maxBytes {
                let handle = try FileHandle(forReadingFrom: url)
                defer { try? handle.close() }
                data = handle.readData(ofLength: maxBytes)
                truncated = true
            } else {
                data = try Data(contentsOf: url)
                truncated = false
            }

            let renderer = RendererRegistry.renderer(for: url)
                ?? ((try? url.resourceValues(forKeys: [.contentTypeKey]).contentType).flatMap { RendererRegistry.renderer(for: $0) })
                ?? RendererRegistry.renderer(for: .json)
            guard let renderer else {
                logger.error("No renderer found for url: \(url.path, privacy: .public)")
                handler(CocoaError(.fileReadUnsupportedScheme))
                return
            }

            let rendererName = String(describing: type(of: renderer))
            logger.notice("Renderer selected: \(rendererName, privacy: .public) for file: \(url.lastPathComponent, privacy: .public)")

            let input = PreviewInput(data: data, url: url, wasTruncatedByReader: truncated)
            let html = renderer.renderHTML(input: input, settings: settings)

            logger.notice("Rendered HTML (\(html.utf8.count) bytes) for \(url.lastPathComponent, privacy: .public)")

            self.webView.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
            handler(nil)
        } catch {
            logger.error("preparePreviewOfFile ERROR: \(error.localizedDescription, privacy: .public)")
            let body = """
            <div class="lp-banner lp-banner-error">Die Datei konnte nicht gelesen werden: \
            \(HTMLEscape.escape(error.localizedDescription))</div>
            """
            let html = HTMLDocument.wrap(body: body,
                                         title: url.lastPathComponent,
                                         css: CSSGenerator.generateCSS(settings: settings))
            self.webView.loadHTMLString(html, baseURL: nil)
            handler(nil)
        }
    }
}
