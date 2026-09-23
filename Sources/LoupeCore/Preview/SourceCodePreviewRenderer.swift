import Foundation
import UniformTypeIdentifiers

public struct SourceCodePreviewRenderer: PreviewRenderer, Sendable {

    public static let supportedExtensions: Set<String> = [
        "swift",
        "rs",
        "py", "pyw",
        "js", "mjs", "cjs",
        "ts", "tsx", "jsx",
        "go",
        "c", "h",
        "cpp", "cc", "cxx", "hpp", "hxx", "h++",
        "java",
        "kt", "kts",
        "sh", "bash", "zsh",
        "sql",
        "yaml", "yml",
        "css", "scss", "sass", "less",
        "xml",
        "php",
        "rb",
        "dockerfile", "docker",
        "makefile", "make",
        "toml", "ini"
    ]

    public static var supportedTypes: [UTType] {
        var types: [UTType] = [
            .sourceCode,
            .swiftSource,
            .cSource,
            .cHeader,
            .cPlusPlusSource,
            .cPlusPlusHeader,
            .script,
            .shellScript,
            .xml
        ]
        let customUTIs = [
            "public.python-script",
            "com.netscape.javascript-source",
            "org.rust-lang.rust-script",
            "org.golang.go-script",
            "com.sun.java-source",
            "org.kotlinlang.source",
            "org.iso.sql",
            "public.yaml",
            "public.css"
        ]
        for uti in customUTIs {
            if let t = UTType(uti), !types.contains(t) {
                types.append(t)
            }
        }
        for ext in supportedExtensions {
            if let t = UTType(filenameExtension: ext), !types.contains(t) {
                types.append(t)
            }
        }
        return types
    }

    public init() {}

    public func renderHTML(input: PreviewInput, settings: LoupeSettings) -> String {
        let filename = input.url.lastPathComponent
        let ext = input.url.pathExtension.lowercased()
        let lang = SupportedLanguage.from(identifier: ext.isEmpty ? filename : ext)
        let rawCode = String(decoding: input.data, as: UTF8.self)

        let body = renderBody(
            code: rawCode,
            filename: filename,
            language: lang,
            settings: settings,
            wasTruncated: input.wasTruncatedByReader,
            totalBytes: input.data.count
        )

        let css = CSSGenerator.generateCodeCSS(settings: settings)
        return HTMLDocument.wrap(
            body: body,
            title: filename,
            css: css,
            csp: HTMLDocument.contentSecurityPolicy
        )
    }

    public func renderBody(
        code: String,
        filename: String,
        language: SupportedLanguage,
        settings: LoupeSettings,
        wasTruncated: Bool,
        totalBytes: Int
    ) -> String {
        var html = "<div class=\"lp-code-container\">\n"

        if wasTruncated {
            html += """
            <div class=\"lp-banner lp-banner-notice\">
                Vorschau gekürzt (Datei ist größer als \(ParseLimits().maxBytes / (1024 * 1024)) MB)
            </div>\n
            """
        }

        let highlighted: String
        if settings.enableSyntaxHighlighting {
            highlighted = SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: language.rawValue)
        } else {
            highlighted = HTMLSanitizer.escapeHTML(code)
        }

        // Split into lines
        // Note: wrapToken ensures no open spans cross \n!
        let lines = highlighted.components(separatedBy: "\n")
        let lineCount = lines.count

        let sizeFormatted = formatFileSize(totalBytes)
        let langBadge = language != .unknown ? language.displayName : (language.rawValue.isEmpty ? "CODE" : language.rawValue.uppercased())

        html += """
        <div class="lp-toolbar">
            <div class="lp-toolbar-left">
                <span class="lp-filename">\(HTMLSanitizer.escapeHTML(filename))</span>
                <span class="lp-badge">\(HTMLSanitizer.escapeHTML(langBadge))</span>
            </div>
            <div class="lp-toolbar-right">
                <span>\(lineCount) \(lineCount == 1 ? "Zeile" : "Zeilen")</span>
                <span>\(sizeFormatted)</span>
            </div>
        </div>
        """

        html += "<div class=\"lp-code-scroll\">\n"
        html += "<table class=\"lp-code-table\"><tbody>\n"

        for (index, line) in lines.enumerated() {
            let lineNum = index + 1
            let content = line.isEmpty ? "&ZeroWidthSpace;" : line
            html += "<tr><td class=\"lp-line-no\">\(lineNum)</td><td class=\"lp-line-code\">\(content)</td></tr>\n"
        }

        html += "</tbody></table>\n"
        html += "</div>\n"
        html += "</div>\n"

        return html
    }

    private func formatFileSize(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024.0)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024.0 * 1024.0))
        }
    }
}
