import Foundation

/// Rubriken, die sich in der Companion-App einzeln abschalten lassen.
/// Jeder Renderer gehoert genau einer Rubrik an (`PreviewRenderer.category`).
public enum PreviewCategory: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case markdown, json, table, log, code

    public var displayName: String {
        switch self {
        case .markdown: return "Markdown"
        case .json:     return "JSON"
        case .table:    return "Tabellen (TSV)"
        case .log:      return "Log-Dateien"
        case .code:     return "Code (alle Sprachen, Skripte, XML)"
        }
    }
}
