import AppKit
import LoupeCore
import WebKit

/// Fenster fuer eine per Doppelklick (oder Ablage > Oeffnen) geoeffnete Datei: dieselbe Ansicht wie Quick Look
/// (gleiche PreviewPipeline), nur in einem normalen Fenster, das offen bleibt, sich vergroessern und neu laden laesst.
///
/// WebKit braucht in der Sandbox das Recht `network.client` (sonst startet sein Netzwerkprozess nicht und das
/// Fenster bleibt schwarz; QLPreviewView scheitert genauso). Geladen wird trotzdem nichts aus dem Netz: Die Seiten
/// tragen die CSP der Renderer (`default-src 'none'`), JavaScript ist aus, und jede Navigation ausser Sprungmarken
/// wird abgefangen (Webadressen gehen an den Standardbrowser).
@MainActor
final class DocumentWindowController: NSWindowController, WKNavigationDelegate, NSWindowDelegate {
    let url: URL
    private let webView: WKWebView
    private let accessed: Bool
    var onClose: ((DocumentWindowController) -> Void)?

    init(url: URL) {
        self.url = url
        // Freigabe der Sandbox fuer per Panel gewaehlte Dateien, solange das Fenster offen ist (Neu laden)
        accessed = url.startAccessingSecurityScopedResource()
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        config.websiteDataStore = .nonPersistent()
        webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsMagnification = true

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 820),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = url.lastPathComponent
        window.representedURL = url  // Dateisymbol in der Titelleiste, Cmd-Klick zeigt den Pfad
        window.contentView = webView
        window.setFrameAutosaveName("LoupeDocument")
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
        webView.navigationDelegate = self
        reload()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Datei neu einlesen, z. B. nachdem sie im Editor geaendert wurde.
    func reload() {
        let settings = LoupeSettings.load()
        let html: String
        do {
            // Wer eine Datei ausdruecklich in Loupe oeffnet, will die Loupe-Ansicht, auch wenn die Rubrik fuer
            // Quick Look abgeschaltet ist
            switch try PreviewPipeline.render(url: url, settings: settings, respectToggles: false) {
            case .html(let s): html = s
            case .plainText(let text):
                html = HTMLDocument.wrap(body: "<pre>\(HTMLEscape.escape(text))</pre>", title: url.lastPathComponent,
                                         css: CSSGenerator.generateCSS(settings: settings))
            case .unsupported:
                html = PreviewPipeline.errorHTML(message: settings.l10n.noPreviewForType,
                                                 title: url.lastPathComponent, settings: settings)
            }
        } catch {
            html = PreviewPipeline.errorHTML(message: error.localizedDescription, title: url.lastPathComponent, settings: settings)
        }
        webView.loadHTMLString(html, baseURL: nil)
    }

    @objc func reloadDocument(_ sender: Any?) { reload() }

    // Nur das eigene Dokument laden; Sprungmarken erlaubt, Webadressen und Mail im Standardprogramm, alles andere zu
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
        guard let target = action.request.url else { return decisionHandler(.cancel) }
        if target.scheme == "about" {
            return decisionHandler(.allow)  // loadHTMLString und Sprungmarken (about:blank#…)
        }
        if action.navigationType == .linkActivated, ["http", "https", "mailto"].contains(target.scheme?.lowercased() ?? "") {
            NSWorkspace.shared.open(target)
        }
        decisionHandler(.cancel)
    }

    func windowWillClose(_ notification: Notification) {
        if accessed { url.stopAccessingSecurityScopedResource() }
        onClose?(self)
    }
}
