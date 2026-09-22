import Foundation

public enum HTMLDocument {
    /// Die CSP steht an genau EINER Stelle. Jede Kopie waere eine Stelle,
    /// an der sie versehentlich abweichen kann.
    public static let contentSecurityPolicy =
        "default-src 'none'; style-src 'unsafe-inline'; img-src 'none'"

    public static func wrap(body: String, title: String, css: String) -> String {
        """
        <!DOCTYPE html>
        <html lang="de">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta http-equiv="Content-Security-Policy" content="\(contentSecurityPolicy)">
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
