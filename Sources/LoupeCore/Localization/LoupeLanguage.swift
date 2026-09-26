import Foundation

/// Sprache der Begleit-App (Fenster und Menue). Die Quick-Look-Vorschau wird
/// nicht uebersetzt.
public enum LoupeLanguage: String, CaseIterable, Codable, Equatable, Sendable {
    case en, de

    /// Erste bekannte Sprache aus der Vorzugsliste von macOS; sonst Englisch.
    public static func resolve(preferred: [String]) -> LoupeLanguage {
        for code in preferred {
            let base = code.lowercased().split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map(String.init) ?? ""
            if let lang = LoupeLanguage(rawValue: base) { return lang }
        }
        return .en
    }

    public static var system: LoupeLanguage { resolve(preferred: Locale.preferredLanguages) }
}

/// Die Einstellung in der App: der Sprache des Systems folgen oder fest waehlen.
public enum LoupeLanguageSetting: String, CaseIterable, Codable, Equatable, Sendable {
    case system, en, de

    public func resolved(preferred: [String] = Locale.preferredLanguages) -> LoupeLanguage {
        switch self {
        case .system: return LoupeLanguage.resolve(preferred: preferred)
        case .en: return .en
        case .de: return .de
        }
    }

    /// Anzeigename -- die festen Sprachen stehen in ihrer EIGENEN Sprache,
    /// damit man sie auch in der falschen Oberflaeche wiederfindet.
    public func displayName(_ lang: LoupeLanguage) -> String {
        switch self {
        case .system: return lang == .de ? "System" : "System"
        case .en: return "English"
        case .de: return "Deutsch"
        }
    }
}
