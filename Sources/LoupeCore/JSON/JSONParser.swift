import Foundation

/// Grenzen aus Spec §7. Werte sind dort begruendet und gelten als Vertrag.
public struct ParseLimits: Sendable {
    public var maxBytes: Int
    public var maxNodes: Int
    public var maxChildrenPerContainer: Int
    public var maxDepth: Int
    public var maxStringDisplayLength: Int

    public init(maxBytes: Int = 20 * 1024 * 1024,
                maxNodes: Int = 20_000,
                maxChildrenPerContainer: Int = 1_000,
                maxDepth: Int = 64,
                maxStringDisplayLength: Int = 4096) {
        self.maxBytes = maxBytes
        self.maxNodes = maxNodes
        self.maxChildrenPerContainer = maxChildrenPerContainer
        self.maxDepth = maxDepth
        self.maxStringDisplayLength = maxStringDisplayLength
    }
}

public struct JSONParser {
    private var lexer: JSONLexer
    private let limits: ParseLimits
    private let wasTruncatedByReader: Bool

    private var lookahead: Token?
    private var diagnostics: [Diagnostic] = []
    private var nodeCount = 0
    private var hitLimit: LimitKind?

    /// Letzter vollstaendig gelesener Wert je Ebene -- traegt den Teilbaum,
    /// falls weiter unten etwas bricht.
    private var partialRoot: JSONValue?

    public init(bytes: [UInt8],
                limits: ParseLimits = ParseLimits(),
                wasTruncatedByReader: Bool = false) {
        self.lexer = JSONLexer(bytes: bytes)
        self.limits = limits
        self.wasTruncatedByReader = wasTruncatedByReader
    }

    private mutating func peek() throws -> Token {
        if let t = lookahead { return t }
        let t = try lexer.next()
        lookahead = t
        return t
    }

    private mutating func advance() throws -> Token {
        let t = try peek()
        lookahead = nil
        return t
    }

    public mutating func parse() -> ParseResult {
        do {
            let first = try peek()
            if first.kind == .endOfInput {
                diagnostics.append(Diagnostic(severity: .error,
                                              message: "Die Datei ist leer.",
                                              position: first.position))
                return ParseResult(root: nil, outcome: .failed(at: first.position),
                                   diagnostics: diagnostics)
            }
            let root = try parseValue(depth: 0)
            partialRoot = root

            let trailing = try peek()
            if trailing.kind != .endOfInput {
                // Direkt nach einem vollstaendigen Wert kommt noch Inhalt --
                // der klassische JSON-Lines-Fall. Das ist eine hilfreichere
                // Meldung als "unerwartetes Zeichen".
                diagnostics.append(Diagnostic(
                    severity: .error,
                    message: "Inhalt nach dem Ende des Dokuments — möglicherweise JSON Lines?",
                    position: trailing.position))
                return ParseResult(root: root, outcome: .failed(at: trailing.position),
                                   diagnostics: diagnostics)
            }
            return ParseResult(root: root, outcome: finalOutcome(), diagnostics: diagnostics)
        } catch let e as LexError {
            return failure(message: e.message, at: e.position)
        } catch let e as ParseError {
            // Der Bruch kann TIEFER als die Wurzel liegen (z. B. innerhalb
            // eines Objekts) -- dann ist `partialRoot` noch nil, weil die
            // Wurzel selbst nie vollstaendig gelesen wurde. `e.partial`
            // traegt in diesem Fall den bis dahin gelesenen Teilbaum der
            // naechsten aeusseren Ebene. Ist `partialRoot` bereits gesetzt
            // (Bruch NACH einem vollstaendigen Wurzelwert, z. B. JSON Lines),
            // hat der Vorrang -- der ist vollstaendiger als jedes `partial`.
            if partialRoot == nil { partialRoot = e.partial }
            return failure(message: e.message, at: e.position)
        } catch {
            return failure(message: "Unerwarteter Fehler beim Lesen.",
                           at: Position(line: 1, column: 1, offset: 0))
        }
    }

    /// Wenn WIR gekuerzt haben, ist die Datei nicht kaputt -- nur unvollstaendig
    /// gelesen. Diese Unterscheidung ist der Kern von Spec §8.
    private func finalOutcome() -> ParseOutcome {
        if let kind = hitLimit { return .truncatedByLimit(kind) }
        if wasTruncatedByReader { return .truncatedByLimit(.bytes) }
        return .complete
    }

    private mutating func failure(message: String, at position: Position) -> ParseResult {
        if wasTruncatedByReader {
            // Der Bruch ist Folge UNSERER Kuerzung, nicht eines Dateifehlers.
            diagnostics.append(Diagnostic(
                severity: .notice,
                message: "Datei bei \(limits.maxBytes / (1024 * 1024)) MB abgeschnitten — der Rest wurde nicht gelesen.",
                position: position))
            return ParseResult(root: partialRoot, outcome: .truncatedByLimit(.bytes),
                               diagnostics: diagnostics)
        }
        diagnostics.append(Diagnostic(severity: .error, message: message, position: position))
        return ParseResult(root: partialRoot, outcome: .failed(at: position),
                           diagnostics: diagnostics)
    }
}

struct ParseError: Error {
    let message: String
    let position: Position
    var partial: JSONValue? = nil
}

extension JSONParser {

    mutating func parseValue(depth: Int) throws -> JSONValue {
        nodeCount += 1
        let token = try advance()
        switch token.kind {
        case .braceOpen:    return try parseObject(depth: depth + 1, at: token.position)
        case .bracketOpen:  return try parseArray(depth: depth + 1, at: token.position)
        case .string(let s):  return .string(s)
        case .number(let n):  return .number(n)
        case .literalTrue:    return .bool(true)
        case .literalFalse:   return .bool(false)
        case .literalNull:    return .null
        case .braceClose, .bracketClose, .colon, .comma:
            throw ParseError(message: "Wert erwartet", position: token.position)
        case .endOfInput:
            throw ParseError(message: "Datei endet unerwartet — Wert erwartet",
                             position: token.position)
        }
    }

    mutating func parseObject(depth: Int, at open: Position) throws -> JSONValue {
        var members: [Member] = []
        if try peek().kind == .braceClose {
            _ = try advance()
            return .object(members: [], omitted: 0)
        }
        while true {
            let keyToken = try advance()
            guard case .string(let key) = keyToken.kind else {
                throw ParseError(message: "Schlüssel in Anführungszeichen erwartet",
                                 position: keyToken.position,
                                 partial: .object(members: members, omitted: 0))
            }
            let colon = try advance()
            guard colon.kind == .colon else {
                throw ParseError(message: "':' nach dem Schlüssel erwartet",
                                 position: colon.position,
                                 partial: .object(members: members, omitted: 0))
            }
            // Der Bruch kann auch INNERHALB des Werts liegen (parseValue wirft
            // dort ohne partial, s. dessen eigener throw), nicht nur an einer
            // der obigen Stellen. Nur wenn noch niemand tiefer ein partial
            // gesetzt hat, ist diese Ebene die naechstbeste Stelle dafuer.
            let value: JSONValue
            do {
                value = try parseValue(depth: depth)
            } catch var e as ParseError {
                if e.partial == nil {
                    e.partial = .object(members: members, omitted: 0)
                }
                throw e
            }
            members.append(Member(key: key, value: value))

            let sep = try advance()
            if sep.kind == .braceClose { break }
            guard sep.kind == .comma else {
                throw ParseError(message: "Komma erwartet, ',' oder '}' fehlt",
                                 position: sep.position,
                                 partial: .object(members: members, omitted: 0))
            }
            // Nachgestelltes Komma vor } ist laut JSON ungueltig.
            if try peek().kind == .braceClose {
                let brace = try advance()
                throw ParseError(message: "Komma vor '}' ist nicht erlaubt",
                                 position: brace.position,
                                 partial: .object(members: members, omitted: 0))
            }
        }
        return .object(members: members, omitted: 0)
    }

    mutating func parseArray(depth: Int, at open: Position) throws -> JSONValue {
        var items: [JSONValue] = []
        if try peek().kind == .bracketClose {
            _ = try advance()
            return .array(items: [], omitted: 0)
        }
        while true {
            // Gleiche Begruendung wie in parseObject: der Bruch kann innerhalb
            // des Werts liegen, wo parseValue ohne partial wirft.
            let value: JSONValue
            do {
                value = try parseValue(depth: depth)
            } catch var e as ParseError {
                if e.partial == nil {
                    e.partial = .array(items: items, omitted: 0)
                }
                throw e
            }
            items.append(value)
            let sep = try advance()
            if sep.kind == .bracketClose { break }
            guard sep.kind == .comma else {
                throw ParseError(message: "Komma erwartet, ',' oder ']' fehlt",
                                 position: sep.position,
                                 partial: .array(items: items, omitted: 0))
            }
            if try peek().kind == .bracketClose {
                let bracket = try advance()
                throw ParseError(message: "Komma vor ']' ist nicht erlaubt",
                                 position: bracket.position,
                                 partial: .array(items: items, omitted: 0))
            }
        }
        return .array(items: items, omitted: 0)
    }
}
