import Foundation

/// Vereinheitlichte Schwere eines Log-Eintrags. Die Rohschreibweisen der
/// Formate (WARN/warning/W/40/"Error") landen alle auf einem dieser Werte.
public enum LogLevel: Int, CaseIterable, Comparable, Sendable {
    case trace, debug, info, notice, warning, error, fatal

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Kurzes Etikett fuer das Badge.
    public var label: String {
        switch self {
        case .trace: return "TRACE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .notice: return "NOTICE"
        case .warning: return "WARN"
        case .error: return "ERROR"
        case .fatal: return "FATAL"
        }
    }

    /// CSS-Namensteil (`lg-lvl-<cssName>`).
    public var cssName: String {
        switch self {
        case .trace: return "trace"
        case .debug: return "debug"
        case .info: return "info"
        case .notice: return "notice"
        case .warning: return "warning"
        case .error: return "error"
        case .fatal: return "fatal"
        }
    }

    /// Ausgeschriebene Level-Woerter. Einzelbuchstaben (E/W/I) gehoeren NICHT
    /// hierher -- die sind nur im logcat-Kontext eindeutig.
    public static func from(_ token: String) -> LogLevel? {
        switch token.lowercased() {
        case "trace", "verbose", "finest", "finer": return .trace
        case "debug", "dbg", "fine": return .debug
        case "info", "inf", "information": return .info
        case "notice": return .notice
        case "warn", "warning", "wrn": return .warning
        case "error", "err", "severe": return .error
        case "crit", "critical", "fatal", "panic", "emerg", "emergency", "alert": return .fatal
        default: return nil
        }
    }

    /// pino/bunyan: 10 trace, 20 debug, 30 info, 40 warn, 50 error, 60 fatal.
    public static func fromNumeric(_ value: Int) -> LogLevel? {
        switch value {
        case ..<20: return .trace
        case 20..<30: return .debug
        case 30..<40: return .info
        case 40..<50: return .warning
        case 50..<60: return .error
        default: return .fatal
        }
    }

    /// logcat-Buchstaben V/D/I/W/E/F/A.
    static func fromLogcat(_ letter: Character) -> LogLevel? {
        switch letter {
        case "V": return .trace
        case "D": return .debug
        case "I": return .info
        case "W": return .warning
        case "E": return .error
        case "F", "A": return .fatal
        default: return nil
        }
    }
}

public enum LogFormat: Sendable, Equatable {
    /// Zeile ohne erkennbare Struktur.
    case plain
    /// Zeitstempel und/oder Level am Zeilenanfang (die meisten Anwendungs-Logs).
    case generic
    case json
    case logfmt
    /// Common/Combined Log Format (nginx, Apache).
    case access
    /// BSD-syslog / journalctl-Standardausgabe.
    case syslog
    /// macOS `log show`.
    case unifiedLog
    /// Android logcat.
    case logcat

    public var displayName: String {
        switch self {
        case .plain: return "Text"
        case .generic: return "Log"
        case .json: return "JSON Lines"
        case .logfmt: return "logfmt"
        case .access: return "nginx/Apache"
        case .syslog: return "syslog"
        case .unifiedLog: return "macOS Log"
        case .logcat: return "logcat"
        }
    }
}

/// Felder einer Access-Log-Zeile.
public struct AccessInfo: Equatable, Sendable {
    public var method: String?
    /// Pfad samt Query; bei kaputter Request-Zeile deren roher Inhalt.
    public var path: String?
    public var proto: String?
    public var status: Int
    public var bytes: String?
    public var referer: String?
    public var userAgent: String?

    public var statusClass: String { "\(status / 100)xx" }
}

/// Zusatzfeld aus JSON/logfmt (alles ausser Zeit/Level/Nachricht/Quelle).
public struct LogField: Equatable, Sendable {
    public var key: String
    public var value: String
    /// true fuer Zeichenketten; Zahlen, Bools und verschachtelte Werte sind false.
    public var isString: Bool
}

/// Eine Folgezeile (Stackframe, mehrzeilige Nachricht) mit ihrer Zeilennummer.
public struct LogLine: Equatable, Sendable {
    public var lineNumber: Int
    public var text: String
}

public struct LogEntry: Sendable {
    public var lineNumber: Int
    public var format: LogFormat
    public var timestamp: String?
    public var level: LogLevel?
    public var source: String?
    public var message: String
    public var fields: [LogField] = []
    public var access: AccessInfo?
    public var continuation: [LogLine] = []
}

public struct LogDocument: Sendable {
    public var entries: [LogEntry]
    /// Anzahl der gezeigten physischen Zeilen.
    public var totalLines: Int
    /// Aeltere Zeilen, die wegen der Zeilengrenze nicht gezeigt werden.
    public var droppedLines: Int
    /// Eintraege je Level (Eintraege ohne Level zaehlen nicht).
    public var levelCounts: [LogLevel: Int]
    /// Haeufigstes strukturierte Format, nil wenn nur Klartext.
    public var dominantFormat: LogFormat?
}
