import Foundation

/// Rubriken, die sich in der Companion-App einzeln abschalten lassen.
/// Jeder Renderer gehoert genau einer Rubrik an (`PreviewRenderer.category`).
public enum PreviewCategory: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case markdown, json, table, log, code

    public func displayName(_ lang: LoupeLanguage) -> String {
        let de = lang == .de
        switch self {
        case .markdown: return "Markdown"
        case .json:     return "JSON"
        case .table:    return de ? "Tabellen (TSV)" : "Tables (TSV)"
        case .log:      return de ? "Log-Dateien" : "Log files"
        case .code:     return de ? "Code (alle Sprachen, Skripte, XML)" : "Code (all languages, scripts, XML)"
        }
    }
}
