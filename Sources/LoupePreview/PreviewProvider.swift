import Foundation
import QuickLookUI
import UniformTypeIdentifiers
import LoupeCore

@objc(PreviewProvider)
public final class PreviewProvider: QLPreviewProvider, QLPreviewingController {

    public override init() { super.init() }

    public func providePreview(
        for request: QLFilePreviewRequest,
        completionHandler: @escaping (QLPreviewReply?, (any Error)?) -> Void
    ) {
        let url = request.fileURL
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        let html = """
        <!DOCTYPE html>
        <html lang="de"><head><meta charset="UTF-8">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; img-src 'none'">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 32px; }
          code { font-family: ui-monospace, SFMono-Regular, monospace; }
          @media (prefers-color-scheme: dark) { body { background: #1e1e1e; color: #f5f5f7; } }
        </style></head>
        <body>
          <h1>Loupe</h1>
          <p>R1-Nachweis: Diese Vorschau stammt von Loupe, nicht von der System-Textvorschau.</p>
          <p><code>\(HTMLEscape.escape(url.lastPathComponent))</code> — \(size) Bytes</p>
        </body></html>
        """
        let reply = QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 840, height: 640)) { _ in
            html.data(using: .utf8) ?? Data()
        }
        reply.title = url.lastPathComponent
        completionHandler(reply, nil)
    }
}
