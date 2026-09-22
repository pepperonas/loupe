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
                //
                // Absichtlich OHNE Ruecksicht auf wasTruncatedByReader: dieser
                // Zweig wird nur erreicht, wenn bereits ein VOLLSTAENDIGER
                // Wert gelesen wurde und danach noch mehr folgt -- die Bytes
                // sind damit kein einzelnes JSON-Dokument, unabhaengig davon,
                // ob WIR zusaetzlich gekuerzt haben. Eine Kuerzung wuerde das
                // nicht "reparieren"; sie koennte den zweiten Wert genauso gut
                // erst mittendrin abschneiden.
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
        if let kind = hitLimit {
            // Der Bruch ist Folge UNSERER Kuerzung (Tiefe/Knoten/Kinder/
            // Stringlaenge), nicht eines Dateifehlers. skipValue() nach einer
            // gegriffenen Grenze hinterlaesst haeufig eine syntaktisch nicht
            // mehr schliessbare Restdatei (Paradebeispiel: eine Tiefenbombe
            // ganz ohne schliessende Klammern) -- der Lexer laeuft beim
            // Wiederaufsetzen der wartenden aeusseren Ebenen dann in
            // .endOfInput, was ohne diese Pruefung faelschlich als
            // .failed(at:) durchgereicht wuerde. Wie beim
            // wasTruncatedByReader-Zweig unten: kein .error-Diagnostic,
            // sonst erscheint eine von UNS gekuerzte, aber sonst gueltige
            // Datei als kaputt (Spec §8) -- symmetrisch dazu haengt auch
            // finalOutcome() bei hitLimit keinen Diagnostic an.
            return ParseResult(root: partialRoot, outcome: .truncatedByLimit(kind),
                               diagnostics: diagnostics)
        }
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
        if depth > limits.maxDepth {
            noteLimit(.depth)
            try skipValue()            // Rest dieses Zweigs verwerfen, nicht absteigen
            return .null
        }
        if nodeCount >= limits.maxNodes {
            noteLimit(.nodes)
            try skipValue()
            return .null
        }
        nodeCount += 1
        let token = try advance()
        switch token.kind {
        case .braceOpen:    return try parseObject(depth: depth + 1, at: token.position)
        case .bracketOpen:  return try parseArray(depth: depth + 1, at: token.position)
        case .string(let s):
            if s.count > limits.maxStringDisplayLength {
                noteLimit(.stringLength)
                return .string(String(s.prefix(limits.maxStringDisplayLength)) + "…")
            }
            return .string(s)
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

    /// Merkt sich die ERSTE greifende Grenze. Spaetere ueberschreiben sie nicht --
    /// die erste erklaert, warum das Ergebnis unvollstaendig ist.
    private mutating func noteLimit(_ kind: LimitKind) {
        if hitLimit == nil { hitLimit = kind }
    }

    /// Ueberspringt einen Wert, ohne einen Baum zu bauen -- ITERATIV.
    /// Rekursives Ueberspringen haette genau den Stapelueberlauf, den die
    /// Tiefenbremse verhindern soll.
    private mutating func skipValue() throws {
        var openContainers = 0
        repeat {
            let token = try advance()
            switch token.kind {
            case .braceOpen, .bracketOpen:   openContainers += 1
            case .braceClose, .bracketClose: openContainers -= 1
            case .endOfInput:                return
            default:                         break
            }
        } while openContainers > 0
    }

    mutating func parseObject(depth: Int, at open: Position) throws -> JSONValue {
        var members: [Member] = []
        var omitted = 0
        // Der Schluessel, dessen WERT gerade gelesen wird. Nur in diesem
        // Fenster -- zwischen dem erfolgreichen Lesen von "key:" und dem
        // erfolgreichen Anhaengen des Members -- kann parseValue in einen
        // TIEFEREN Container abgestiegen sein, dessen eigener catch bereits
        // ein partial gesetzt hat; nur dann wird unten genestet.
        var pendingKey: String? = nil
        // Der GESAMTE Rumpf steckt in einem einzigen do/catch, nicht nur der
        // rekursive parseValue-Aufruf (das war die Luecke in der letzten
        // Runde): der Lexer wird aus fuenf Stellen aufgerufen -- Schluessel-
        // Token, Doppelpunkt, Wert, Trenner-Komma und der Blick voraus aufs
        // schliessende '}'. Ein Bruch KANN aus jeder davon kommen, nicht nur
        // aus dem Wert (Beleg: ein Trailing-Komma-peek() vor einem kaputten
        // Token liegt AUSSERHALB des Werts).
        do {
            if try peek().kind == .braceClose {
                _ = try advance()
                return .object(members: [], omitted: 0)
            }
            while true {
                let keyToken = try advance()
                guard case .string(let key) = keyToken.kind else {
                    throw ParseError(message: "Schlüssel in Anführungszeichen erwartet",
                                     position: keyToken.position)
                }
                pendingKey = key
                let colon = try advance()
                guard colon.kind == .colon else {
                    throw ParseError(message: "':' nach dem Schlüssel erwartet",
                                     position: colon.position)
                }
                let value = try parseValue(depth: depth)
                if members.count < limits.maxChildrenPerContainer {
                    members.append(Member(key: key, value: value))
                } else {
                    omitted += 1
                    noteLimit(.children)
                }
                pendingKey = nil

                let sep = try advance()
                if sep.kind == .braceClose { break }
                guard sep.kind == .comma else {
                    throw ParseError(message: "Komma erwartet, ',' oder '}' fehlt",
                                     position: sep.position)
                }
                // Nachgestelltes Komma vor } ist laut JSON ungueltig.
                if try peek().kind == .braceClose {
                    let brace = try advance()
                    throw ParseError(message: "Komma vor '}' ist nicht erlaubt",
                                     position: brace.position)
                }
            }
            return .object(members: members, omitted: omitted)
        } catch var e as ParseError {
            // partial ist an JEDER Wurfstelle oben bewusst NICHT gesetzt
            // (Default nil): nur diese eine Stelle entscheidet, ob genestet
            // wird. Traegt e schon ein partial UND war ein Schluessel gerade
            // in Arbeit, kam der Bruch aus dessen WERT (einem tieferen
            // Container) -- der gehoert unter diesen Schluessel, nicht lose
            // daneben. Sonst (kein partial, oder der Bruch lag zwischen zwei
            // Members, wo kein Schluessel offen ist) zaehlen nur die bereits
            // vollstaendigen Members dieser Ebene.
            if let deeper = e.partial, let key = pendingKey {
                e.partial = .object(members: members + [Member(key: key, value: deeper)],
                                    omitted: omitted)
            } else {
                e.partial = .object(members: members, omitted: omitted)
            }
            throw e
        } catch let e as LexError {
            throw ParseError(message: e.message, position: e.position,
                             partial: .object(members: members, omitted: omitted))
        }
    }

    mutating func parseArray(depth: Int, at open: Position) throws -> JSONValue {
        var items: [JSONValue] = []
        var omitted = 0
        // Gleiche Begruendung wie in parseObject: der GESAMTE Rumpf steckt in
        // einem do/catch, nicht nur der rekursive parseValue-Aufruf -- auch
        // hier kann der Lexer aus dem Trenner-Komma oder dem Blick voraus
        // aufs schliessende ']' werfen, ausserhalb des Werts.
        do {
            if try peek().kind == .bracketClose {
                _ = try advance()
                return .array(items: [], omitted: 0)
            }
            while true {
                let value = try parseValue(depth: depth)
                if items.count < limits.maxChildrenPerContainer {
                    items.append(value)
                } else {
                    omitted += 1
                    noteLimit(.children)
                }
                let sep = try advance()
                if sep.kind == .bracketClose { break }
                guard sep.kind == .comma else {
                    throw ParseError(message: "Komma erwartet, ',' oder ']' fehlt",
                                     position: sep.position)
                }
                if try peek().kind == .bracketClose {
                    let bracket = try advance()
                    throw ParseError(message: "Komma vor ']' ist nicht erlaubt",
                                     position: bracket.position)
                }
            }
            return .array(items: items, omitted: omitted)
        } catch var e as ParseError {
            // Kein "pendingIndex" noetig wie bei parseObject: ein bereits
            // gesetztes partial kann nur aus dem rekursiven parseValue fuer
            // das NAECHSTE Element stammen (items enthaelt es noch nicht),
            // also wird es einfach angehaengt.
            if let deeper = e.partial {
                e.partial = .array(items: items + [deeper], omitted: omitted)
            } else {
                e.partial = .array(items: items, omitted: omitted)
            }
            throw e
        } catch let e as LexError {
            throw ParseError(message: e.message, position: e.position,
                             partial: .array(items: items, omitted: omitted))
        }
    }
}
