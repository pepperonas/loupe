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

    /// Basis-Schriftgroesse fuer die Monospace-Baumdarstellung (JSON).
    public var baseFontSizePx: Int {
        switch self {
        case .small: return 12
        case .standard: return 13
        case .large: return 15
        }
    }

    /// Basis-Schriftgroesse fuer Markdown-Fliesskomma-Text.
    public var markdownBaseFontSizePx: Int {
        switch self {
        case .small: return 14
        case .standard: return 16
        case .large: return 18
        }
    }

    /// Schriftgroesse fuer Codebloecke in Markdown.
    public var codeFontSizePx: Int {
        switch self {
        case .small: return 12
        case .standard: return 13
        case .large: return 15
        }
    }
}

public enum LoupeContentWidth: String, CaseIterable, Codable, Equatable, Sendable {
    case compact = "compact"
    case standard = "standard"
    case wide = "wide"
    case full = "full"

    public var displayName: String {
        switch self {
        case .compact: return "Kompakt (680px)"
        case .standard: return "Standard (840px)"
        case .wide: return "Breit (1040px)"
        case .full: return "Volle Breite"
        }
    }

    public var cssMaxWidth: String {
        switch self {
        case .compact: return "680px"
        case .standard: return "840px"
        case .wide: return "1040px"
        case .full: return "100%"
        }
    }
}

public struct LoupeSettings: Codable, Equatable, Sendable {
    public var appearance: LoupeAppearance
    public var textSize: LoupeTextSize
    /// Sichtbare Zeilen, die beim Oeffnen aufgeklappt sein duerfen (Spec §6).
    public var expansionLineBudget: Int
    public var showTypeBadges: Bool
    public var contentWidth: LoupeContentWidth
    public var allowRemoteImages: Bool
    public var enableSyntaxHighlighting: Bool
    public var showLineNumbers: Bool
    public var maxFileSizeBytes: Int

    public static let appGroupSuiteName = "group.io.celox.loupe"
    public static let settingsKey = "io.celox.loupe.settings"

    public init(
        appearance: LoupeAppearance = .system,
        textSize: LoupeTextSize = .standard,
        expansionLineBudget: Int = 300,
        showTypeBadges: Bool = true,
        contentWidth: LoupeContentWidth = .standard,
        allowRemoteImages: Bool = false,
        enableSyntaxHighlighting: Bool = true,
        showLineNumbers: Bool = false,
        maxFileSizeBytes: Int = 5 * 1024 * 1024
    ) {
        self.appearance = appearance
        self.textSize = textSize
        self.expansionLineBudget = expansionLineBudget
        self.showTypeBadges = showTypeBadges
        self.contentWidth = contentWidth
        self.allowRemoteImages = allowRemoteImages
        self.enableSyntaxHighlighting = enableSyntaxHighlighting
        self.showLineNumbers = showLineNumbers
        self.maxFileSizeBytes = maxFileSizeBytes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.appearance = try container.decodeIfPresent(LoupeAppearance.self, forKey: .appearance) ?? .system
        self.textSize = try container.decodeIfPresent(LoupeTextSize.self, forKey: .textSize) ?? .standard
        self.expansionLineBudget = try container.decodeIfPresent(Int.self, forKey: .expansionLineBudget) ?? 300
        self.showTypeBadges = try container.decodeIfPresent(Bool.self, forKey: .showTypeBadges) ?? true
        self.contentWidth = try container.decodeIfPresent(LoupeContentWidth.self, forKey: .contentWidth) ?? .standard
        self.allowRemoteImages = try container.decodeIfPresent(Bool.self, forKey: .allowRemoteImages) ?? false
        self.enableSyntaxHighlighting = try container.decodeIfPresent(Bool.self, forKey: .enableSyntaxHighlighting) ?? true
        self.showLineNumbers = try container.decodeIfPresent(Bool.self, forKey: .showLineNumbers) ?? false
        self.maxFileSizeBytes = try container.decodeIfPresent(Int.self, forKey: .maxFileSizeBytes) ?? (5 * 1024 * 1024)
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
