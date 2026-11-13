import Foundation
import UniformTypeIdentifiers

/// Java-Keystores (`.jks`, `.keystore`): Format, Aliase und Zertifikate --
/// alles, was ohne Passwort lesbar ist. Private Schluessel bleiben verschluesselt
/// und werden nie angezeigt.
public struct KeystorePreviewRenderer: PreviewRenderer {

    /// Eigener Typ: macOS vergibt fuer `.jks` nur einen dynamischen Typ.
    public static let typeIdentifier = "io.celox.loupe.java-keystore"

    public static let supportedExtensions: Set<String> = ["jks", "keystore"]

    /// Keystores sind wenige Kilobyte gross; ein Truststore mit 150 Zertifikaten ~200 KB.
    public static let maxReadBytes = 4 * 1024 * 1024

    public static var readStrategy: PreviewReadStrategy { .headAtMost(maxBytes: maxReadBytes) }

    public static let category: PreviewCategory = .keystore

    /// Binaerdatei: als Rohtext waere sie Zeichensalat.
    public static var plainTextWhenDisabled: Bool { false }

    /// Mehr Eintraege werden nicht gezeichnet.
    public static let maxEntriesShown = 200

    public static var supportedTypes: [UTType] {
        [UTType(typeIdentifier)].compactMap { $0 }
    }

    public init() {}

    public func renderHTML(input: PreviewInput, settings: LoupeSettings) -> String {
        let document = KeystoreParser.parse(input.data)
        let body = renderBody(document: document,
                              filename: input.url.lastPathComponent,
                              totalBytes: input.data.count,
                              truncated: input.wasTruncatedByReader,
                              now: Date())
        return HTMLDocument.wrap(body: body,
                                 title: input.url.lastPathComponent,
                                 css: CSSGenerator.generateKeystoreCSS(settings: settings),
                                 csp: HTMLDocument.contentSecurityPolicy)
    }

    public func renderBody(document doc: KeystoreDocument, filename: String,
                           totalBytes: Int, truncated: Bool, now: Date) -> String {
        var html = "<div class=\"lp-code-container ks\">\n"

        var left = "<span class=\"lp-filename\">\(HTMLEscape.escape(filename))</span>"
        left += "<span class=\"lp-badge\">\(HTMLEscape.escape(doc.format == .unknown ? "KEYSTORE" : doc.format.rawValue))</span>"
        var right = ""
        let total = doc.declaredEntries ?? doc.entries.count
        if doc.format != .unknown, doc.format != .bks {
            right += "<span>\(total) \(total == 1 ? "Eintrag" : "Einträge")</span>"
        }
        right += "<span>\(formatSize(totalBytes))</span>"
        html += """
        <div class="lp-toolbar">
            <div class="lp-toolbar-left">\(left)</div>
            <div class="lp-toolbar-right">\(right)</div>
        </div>

        """

        var notes = doc.notes
        if truncated {
            notes.insert("Datei abgeschnitten — nur der Anfang wurde gelesen.", at: 0)
        }
        if !notes.isEmpty {
            html += "<div class=\"lp-banner lp-banner-notice\">\(HTMLEscape.escape(notes.joined(separator: " ")))</div>\n"
        }

        html += "<div class=\"lp-code-scroll ks-body\">\n"
        if doc.entries.isEmpty, doc.format == .jks || doc.format == .jceks || doc.format == .pkcs12 {
            html += "<div class=\"ks-empty\">Keine Einträge lesbar.</div>\n"
        }
        for entry in doc.entries.prefix(Self.maxEntriesShown) {
            html += renderEntry(entry, now: now)
        }
        if doc.entries.count > Self.maxEntriesShown {
            html += "<div class=\"ks-empty\">… \(doc.entries.count - Self.maxEntriesShown) weitere Einträge nicht dargestellt</div>\n"
        }
        if doc.entries.contains(where: { $0.kind != .trustedCertificate }) {
            html += "<div class=\"ks-foot\">Schlüssel bleiben verschlüsselt. Loupe zeigt nur, was ohne Passwort lesbar ist.</div>\n"
        }
        html += "</div>\n</div>\n"
        return html
    }

    // MARK: - Eintraege

    private func renderEntry(_ entry: KeystoreEntry, now: Date) -> String {
        let kind: (label: String, css: String)
        switch entry.kind {
        case .privateKey: kind = ("Privater Schlüssel", "ks-k-key")
        case .trustedCertificate: kind = ("Zertifikat", "ks-k-cert")
        case .secretKey: kind = ("Geheimer Schlüssel", "ks-k-secret")
        }
        var html = "<section class=\"ks-entry\">\n<header class=\"ks-head\">"
        html += "<span class=\"ks-alias\">\(HTMLEscape.escape(entry.alias))</span>"
        html += "<span class=\"ks-kind \(kind.css)\">\(kind.label)</span>"
        if let created = entry.created {
            html += "<span class=\"ks-created\">angelegt \(Self.day(created))</span>"
        }
        html += "</header>\n"

        if let cert = entry.certificates.first {
            html += "<table class=\"ks-table\"><tbody>\n"
            html += row("Inhaber", HTMLEscape.escape(cert.subject))
            html += row("Aussteller", cert.isSelfSigned
                        ? "<span class=\"ks-dim\">selbstsigniert</span>"
                        : HTMLEscape.escape(cert.issuer))
            html += row("Gültig", validity(cert, now: now))
            html += row("Schlüssel", HTMLEscape.escape(cert.publicKey))
            html += row("Signatur", HTMLEscape.escape(cert.signatureAlgorithm))
            html += row("Seriennummer", "<span class=\"ks-mono\">\(HTMLEscape.escape(cert.serialHex))</span>")
            html += row("SHA-1", "<span class=\"ks-mono\">\(cert.sha1)</span>")
            html += row("SHA-256", "<span class=\"ks-mono\">\(cert.sha256)</span>")
            if entry.certificates.count > 1 {
                let rest = entry.certificates.dropFirst().map { HTMLEscape.escape($0.subject) }
                html += row("Kette", "\(entry.certificates.count) Zertifikate<br>"
                            + rest.map { "<span class=\"ks-dim\">↳ \($0)</span>" }.joined(separator: "<br>"))
            }
            html += "</tbody></table>\n"
        } else if entry.kind == .privateKey {
            html += "<div class=\"ks-empty\">Das Zertifikat ist verschlüsselt abgelegt.</div>\n"
        }
        if entry.unreadableCertificates > 0 {
            let n = entry.unreadableCertificates
            html += "<div class=\"ks-empty\">\(n) \(n == 1 ? "Zertifikat ließ" : "Zertifikate ließen") sich nicht lesen.</div>\n"
        }
        html += "</section>\n"
        return html
    }

    private func row(_ label: String, _ valueHTML: String) -> String {
        "<tr><th>\(label)</th><td>\(valueHTML)</td></tr>\n"
    }

    /// „2026-01-01 bis 2051-01-01“ plus Status: abgelaufen, bald, noch nicht gueltig.
    public func validity(_ cert: X509Summary, now: Date) -> String {
        guard let from = cert.notBefore, let until = cert.notAfter else {
            return "<span class=\"ks-dim\">unbekannt</span>"
        }
        var html = "\(Self.day(from)) bis \(Self.day(until))"
        let days = Int((until.timeIntervalSince(now) / 86_400).rounded(.down))
        if now < from {
            html += " <span class=\"ks-state ks-warn\">noch nicht gültig</span>"
        } else if now > until {
            html += " <span class=\"ks-state ks-bad\">abgelaufen</span>"
        } else if days < 90 {
            html += " <span class=\"ks-state ks-warn\">läuft in \(days) \(days == 1 ? "Tag" : "Tagen") ab</span>"
        } else {
            html += " <span class=\"ks-state ks-ok\">gültig</span>"
        }
        return html
    }

    /// Datum als JJJJ-MM-TT in UTC -- unabhaengig von Sprache und Zeitzone des Macs.
    public static func day(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        func pad(_ n: Int, _ width: Int) -> String {
            let s = String(n)
            return String(repeating: "0", count: max(0, width - s.count)) + s
        }
        return "\(pad(c.year ?? 0, 4))-\(pad(c.month ?? 0, 2))-\(pad(c.day ?? 0, 2))"
    }

    private func formatSize(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }
}
