import Foundation

/// Von der Datei zur fertigen Vorschau: Renderer waehlen, Schalter beachten, den passenden Teil lesen, rendern.
/// Gemeinsam fuer die Quick-Look-Erweiterung (Leertaste) und das Dokumentfenster der App (Doppelklick),
/// damit beide garantiert dasselbe zeigen.
public enum PreviewPipeline {
    public enum Output: Equatable, Sendable {
        /// Fertiges HTML-Dokument mit CSP.
        case html(String)
        /// Rubrik abgeschaltet: Rohtext, wie macOS ohne Loupe.
        case plainText(String)
        /// Rubrik abgeschaltet, Binaerformat: keine Vorschau (Quick Look zeigt die Datei-Karte).
        case unsupported
    }

    /// - Parameter respectToggles: Die Schalter der App gelten fuer Quick Look. Wer eine Datei ausdruecklich in Loupe
    ///   oeffnet, will die Loupe-Ansicht, deshalb rendert das Dokumentfenster auch abgeschaltete Rubriken.
    public static func render(url: URL, settings: LoupeSettings,
                              maxBytes: Int = ParseLimits().maxBytes,
                              respectToggles: Bool = true) throws -> Output {
        let renderer = RendererRegistry.renderer(for: url)
            ?? ((try? url.resourceValues(forKeys: [.contentTypeKey]).contentType).flatMap { RendererRegistry.renderer(for: $0) })
            ?? RendererRegistry.renderer(for: .json)
        guard let renderer else { return .unsupported }

        let type = type(of: renderer)
        if respectToggles && !settings.isEnabled(type.category) {
            guard type.plainTextWhenDisabled else { return .unsupported }
            let read = try PreviewFileReader.read(url: url, strategy: .head, headLimit: maxBytes)
            return .plainText(PlainTextFallback.text(from: read.data))
        }

        // Der Renderer bestimmt, welcher Teil gelesen wird: Logs brauchen das ENDE (dort steht das Neueste),
        // alles andere den Anfang.
        let read = try PreviewFileReader.read(url: url, strategy: type.readStrategy, headLimit: maxBytes)
        let input = PreviewInput(data: read.data, url: url,
                                 wasTruncatedByReader: read.truncatedAtEnd,
                                 skippedBytesAtStart: read.skippedBytesAtStart,
                                 skippedLineBreaks: read.skippedLineBreaks)
        return .html(renderer.renderHTML(input: input, settings: settings))
    }

    /// Fehlerseite im Loupe-Stil, wenn die Datei nicht gelesen werden konnte.
    public static func errorHTML(message: String, title: String, settings: LoupeSettings) -> String {
        let body = """
        <div class="lp-banner lp-banner-error">Die Datei konnte nicht gelesen werden: \
        \(HTMLEscape.escape(message))</div>
        """
        return HTMLDocument.wrap(body: body, title: title, css: CSSGenerator.generateCSS(settings: settings))
    }
}
