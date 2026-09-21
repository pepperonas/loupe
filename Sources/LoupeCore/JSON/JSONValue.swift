import Foundation

/// Stelle im Quelltext. Zeile und Spalte 1-basiert (wie Editoren zaehlen),
/// offset 0-basiert in Bytes.
public struct Position: Equatable, Sendable {
    public let line: Int
    public let column: Int
    public let offset: Int

    public init(line: Int, column: Int, offset: Int) {
        self.line = line
        self.column = column
        self.offset = offset
    }
}

/// Ein Schluessel-Wert-Paar eines Objekts.
///
/// Objekte sind eine LISTE von Paaren, kein Dictionary. Ein Dictionary ist
/// ungeordnet und verwirft doppelte Schluessel still -- beides waere eine
/// Luege ueber die Datei.
public struct Member: Sendable {
    public let key: String
    public let value: JSONValue

    public init(key: String, value: JSONValue) {
        self.key = key
        self.value = value
    }
}

public indirect enum JSONValue: Sendable {
    case null
    case bool(Bool)
    /// Roh als Zeichenkette. Double macht aus 1.0 eine 1, verliert bei grossen
    /// Ganzzahlen Stellen und kippt bei 1e400 ins Unendliche.
    case number(String)
    case string(String)
    case array(items: [JSONValue], omitted: Int)
    case object(members: [Member], omitted: Int)
}

/// Welche Grenze aus Spec §7 gegriffen hat.
public enum LimitKind: String, Equatable, Sendable {
    case bytes, nodes, children, depth, stringLength
}

public struct Diagnostic: Equatable, Sendable {
    public enum Severity: Equatable, Sendable { case error, notice }

    public let severity: Severity
    public let message: String
    public let position: Position

    public init(severity: Severity, message: String, position: Position) {
        self.severity = severity
        self.message = message
        self.position = position
    }
}

public enum ParseOutcome: Equatable, Sendable {
    case complete
    /// WIR haben gekuerzt. Die Datei ist in Ordnung, nur nicht vollstaendig
    /// gelesen. Darf NIEMALS als Fehler dargestellt werden.
    case truncatedByLimit(LimitKind)
    /// Die DATEI ist kaputt.
    case failed(at: Position)
}

public struct ParseResult: Sendable {
    public let root: JSONValue?
    public let outcome: ParseOutcome
    public let diagnostics: [Diagnostic]

    public init(root: JSONValue?, outcome: ParseOutcome, diagnostics: [Diagnostic]) {
        self.root = root
        self.outcome = outcome
        self.diagnostics = diagnostics
    }
}
