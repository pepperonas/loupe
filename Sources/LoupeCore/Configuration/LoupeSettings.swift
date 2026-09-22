import Foundation

public enum LoupeAppearance: String, CaseIterable, Codable, Equatable, Sendable {
    case system, light, dark

    public var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Hell"
        case .dark:   return "Dunkel"
        }
    }
}

public enum LoupeTextSize: String, CaseIterable, Codable, Equatable, Sendable {
    case small, standard, large

    public var displayName: String {
        switch self {
        case .small:    return "Klein"
        case .standard: return "Standard"
        case .large:    return "Groß"
        }
    }

    /// Kleiner als bei MarkLook: der Baum ist durchgehend Monospace,
    /// und Monospace traegt bei gleicher Punktgroesse breiter auf.
    public var baseFontSizePx: Int {
        switch self {
        case .small: return 12
        case .standard: return 13
        case .large: return 15
        }
    }
}

public struct LoupeSettings: Codable, Equatable, Sendable {
    public var appearance: LoupeAppearance
    public var textSize: LoupeTextSize
    /// Sichtbare Zeilen, die beim Oeffnen aufgeklappt sein duerfen (Spec §6).
    public var expansionLineBudget: Int
    public var showTypeBadges: Bool

    public static let appGroupSuiteName = "group.io.celox.loupe"
    public static let settingsKey = "io.celox.loupe.settings"

    public init(appearance: LoupeAppearance = .system,
                textSize: LoupeTextSize = .standard,
                expansionLineBudget: Int = 300,
                showTypeBadges: Bool = true) {
        self.appearance = appearance
        self.textSize = textSize
        self.expansionLineBudget = expansionLineBudget
        self.showTypeBadges = showTypeBadges
    }

    public static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupSuiteName) ?? .standard
    }

    public static func load() -> LoupeSettings {
        let defaults = sharedDefaults
        if let data = defaults.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(LoupeSettings.self, from: data) {
            return settings
        }
        return LoupeSettings()
    }

    public func save() {
        if let data = try? JSONEncoder().encode(self) {
            Self.sharedDefaults.set(data, forKey: Self.settingsKey)
        }
    }
}
