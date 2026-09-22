import Foundation

public enum HTMLDocument {
    /// Die Standard-CSP fuer statische Renderer ohne Bilddarstellung (JSON).
    public static let contentSecurityPolicy =
        "default-src 'none'; style-src 'unsafe-inline'; img-src 'none'"

    /// Liefert die strikte CSP fuer Markdown-Dokumente (Erlaubt Data-URIs fuer Bilder, niemals Skripte).
    public static func markdownCSP(allowRemoteImages: Bool) -> String {
        "default-src 'none'; style-src 'unsafe-inline'; img-src data: cid: \(allowRemoteImages ? "https: http:" : "");"
    }

    public static func wrap(body: String, title: String, css: String, csp: String = contentSecurityPolicy) -> String {
        """
        <!DOCTYPE html>
        <html lang="de">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta http-equiv="Content-Security-Policy" content="\(csp)">
            <title>\(HTMLEscape.escape(title))</title>
            <style>
        \(css)
            </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }
}
