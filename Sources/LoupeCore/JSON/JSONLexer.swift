import Foundation

public enum TokenKind: Equatable, Sendable {
    case braceOpen, braceClose
    case bracketOpen, bracketClose
    case colon, comma
    case string(String)
    case number(String)
    case literalTrue, literalFalse, literalNull
    case endOfInput
}

public struct Token: Equatable, Sendable {
    public let kind: TokenKind
    public let position: Position
    public init(kind: TokenKind, position: Position) {
        self.kind = kind
        self.position = position
    }
}

public struct LexError: Error, Equatable, Sendable {
    public let message: String
    public let position: Position
    public init(message: String, position: Position) {
        self.message = message
        self.position = position
    }
}

public struct JSONLexer {
    private let bytes: [UInt8]
    private var index: Int = 0
    private var line: Int = 1
    private var lineStart: Int = 0

    public init(bytes: [UInt8]) {
        self.bytes = bytes
        // BOM (EF BB BF) ueberspringen -- kein Fehler, nur Rauschen.
        if bytes.count >= 3, bytes[0] == 0xEF, bytes[1] == 0xBB, bytes[2] == 0xBF {
            index = 3
            lineStart = 3
        }
    }

    private var currentPosition: Position {
        Position(line: line, column: index - lineStart + 1, offset: index)
    }

    private mutating func skipWhitespace() {
        while index < bytes.count {
            switch bytes[index] {
            case 0x0A:                      // \n
                index += 1; line += 1; lineStart = index
            case 0x20, 0x09, 0x0D:          // Space, Tab, CR
                index += 1
            default:
                return
            }
        }
    }

    public mutating func next() throws -> Token {
        skipWhitespace()
        guard index < bytes.count else {
            return Token(kind: .endOfInput, position: currentPosition)
        }
        let start = currentPosition
        switch bytes[index] {
        case UInt8(ascii: "{"): index += 1; return Token(kind: .braceOpen, position: start)
        case UInt8(ascii: "}"): index += 1; return Token(kind: .braceClose, position: start)
        case UInt8(ascii: "["): index += 1; return Token(kind: .bracketOpen, position: start)
        case UInt8(ascii: "]"): index += 1; return Token(kind: .bracketClose, position: start)
        case UInt8(ascii: ":"): index += 1; return Token(kind: .colon, position: start)
        case UInt8(ascii: ","): index += 1; return Token(kind: .comma, position: start)
        case UInt8(ascii: "\""): return Token(kind: .string(try lexString(from: start)), position: start)
        case UInt8(ascii: "t"): try expect("true", at: start); return Token(kind: .literalTrue, position: start)
        case UInt8(ascii: "f"): try expect("false", at: start); return Token(kind: .literalFalse, position: start)
        case UInt8(ascii: "n"): try expect("null", at: start); return Token(kind: .literalNull, position: start)
        default: return Token(kind: .number(try lexNumber(from: start)), position: start)
        }
    }

    private mutating func expect(_ word: String, at start: Position) throws {
        let want = Array(word.utf8)
        guard index + want.count <= bytes.count,
              Array(bytes[index ..< index + want.count]) == want else {
            throw LexError(message: "'\(word)' erwartet", position: start)
        }
        index += want.count
    }

    private mutating func lexNumber(from start: Position) throws -> String {
        let begin = index
        if index < bytes.count, bytes[index] == UInt8(ascii: "-") { index += 1 }

        // Ganzzahlteil: entweder genau eine 0, oder 1-9 gefolgt von Ziffern.
        // Eine fuehrende Null wie 01 ist laut JSON ungueltig.
        guard index < bytes.count, isDigit(bytes[index]) else {
            throw LexError(message: "Ziffer erwartet", position: start)
        }
        if bytes[index] == UInt8(ascii: "0") {
            index += 1
            if index < bytes.count, isDigit(bytes[index]) {
                throw LexError(message: "führende Null ist nicht erlaubt", position: start)
            }
        } else {
            while index < bytes.count, isDigit(bytes[index]) { index += 1 }
        }

        if index < bytes.count, bytes[index] == UInt8(ascii: ".") {
            index += 1
            guard index < bytes.count, isDigit(bytes[index]) else {
                throw LexError(message: "Ziffer nach dem Dezimalpunkt erwartet", position: start)
            }
            while index < bytes.count, isDigit(bytes[index]) { index += 1 }
        }

        if index < bytes.count, bytes[index] | 0x20 == UInt8(ascii: "e") {
            index += 1
            if index < bytes.count, bytes[index] == UInt8(ascii: "+") || bytes[index] == UInt8(ascii: "-") {
                index += 1
            }
            guard index < bytes.count, isDigit(bytes[index]) else {
                throw LexError(message: "Ziffer im Exponenten erwartet", position: start)
            }
            while index < bytes.count, isDigit(bytes[index]) { index += 1 }
        }

        return String(decoding: bytes[begin ..< index], as: UTF8.self)
    }

    private func isDigit(_ b: UInt8) -> Bool {
        b >= UInt8(ascii: "0") && b <= UInt8(ascii: "9")
    }

    private mutating func lexString(from start: Position) throws -> String {
        index += 1                      // oeffnendes Anfuehrungszeichen
        var scalars = String.UnicodeScalarView()
        while true {
            guard index < bytes.count else {
                throw LexError(message: "Zeichenkette nicht geschlossen", position: start)
            }
            let b = bytes[index]
            if b == UInt8(ascii: "\"") { index += 1; break }
            if b == UInt8(ascii: "\\") {
                index += 1
                guard index < bytes.count else {
                    throw LexError(message: "Zeichenkette nicht geschlossen", position: start)
                }
                switch bytes[index] {
                case UInt8(ascii: "\""): scalars.append("\""); index += 1
                case UInt8(ascii: "\\"): scalars.append("\\"); index += 1
                case UInt8(ascii: "/"):  scalars.append("/");  index += 1
                case UInt8(ascii: "b"):  scalars.append(UnicodeScalar(8));  index += 1
                case UInt8(ascii: "f"):  scalars.append(UnicodeScalar(12)); index += 1
                case UInt8(ascii: "n"):  scalars.append("\n"); index += 1
                case UInt8(ascii: "r"):  scalars.append("\r"); index += 1
                case UInt8(ascii: "t"):  scalars.append("\t"); index += 1
                case UInt8(ascii: "u"):  scalars.append(try lexUnicodeEscape(from: start))
                default:
                    throw LexError(message: "unbekannte Escape-Sequenz", position: currentPosition)
                }
            } else {
                // Rohbytes sammeln bis zum naechsten Sonderzeichen und am Stueck dekodieren.
                let begin = index
                while index < bytes.count,
                      bytes[index] != UInt8(ascii: "\""),
                      bytes[index] != UInt8(ascii: "\\") {
                    if bytes[index] == 0x0A { line += 1; lineStart = index + 1 }
                    index += 1
                }
                scalars.append(contentsOf: String(decoding: bytes[begin ..< index], as: UTF8.self).unicodeScalars)
            }
        }
        return String(scalars)
    }

    /// Liest \uXXXX. Ein hohes Surrogat MUSS von einem niedrigen gefolgt werden --
    /// sonst entsteht kein gueltiger Unicode-Skalar.
    private mutating func lexUnicodeEscape(from start: Position) throws -> UnicodeScalar {
        let first = try readFourHexDigits(from: start)
        if first >= 0xD800 && first <= 0xDBFF {
            guard index + 1 < bytes.count,
                  bytes[index] == UInt8(ascii: "\\"),
                  bytes[index + 1] == UInt8(ascii: "u") else {
                throw LexError(message: "einzelnes Surrogat ohne Partner", position: start)
            }
            // NUR den Backslash ueberspringen -- readFourHexDigits erwartet index
            // AUF dem 'u' (siehe dessen eigenes `index += 1`, Kommentar "das u").
            // Mit `index += 2` waere das 'u' schon konsumiert und
            // readFourHexDigits wuerde stattdessen die erste Hexziffer verschlucken.
            index += 1
            let second = try readFourHexDigits(from: start)
            guard second >= 0xDC00 && second <= 0xDFFF else {
                throw LexError(message: "ungültiges Surrogatpaar", position: start)
            }
            let combined = 0x10000 + ((first - 0xD800) << 10) + (second - 0xDC00)
            guard let scalar = UnicodeScalar(UInt32(combined)) else {
                throw LexError(message: "ungültiger Unicode-Wert", position: start)
            }
            return scalar
        }
        guard first < 0xD800 || first > 0xDFFF, let scalar = UnicodeScalar(UInt32(first)) else {
            throw LexError(message: "einzelnes Surrogat ohne Partner", position: start)
        }
        return scalar
    }

    private mutating func readFourHexDigits(from start: Position) throws -> Int {
        index += 1                      // das u
        guard index + 4 <= bytes.count else {
            throw LexError(message: "\\u braucht vier Hexziffern", position: start)
        }
        var value = 0
        for _ in 0 ..< 4 {
            let b = bytes[index]
            let digit: Int
            switch b {
            case UInt8(ascii: "0") ... UInt8(ascii: "9"): digit = Int(b - UInt8(ascii: "0"))
            case UInt8(ascii: "a") ... UInt8(ascii: "f"): digit = Int(b - UInt8(ascii: "a")) + 10
            case UInt8(ascii: "A") ... UInt8(ascii: "F"): digit = Int(b - UInt8(ascii: "A")) + 10
            default: throw LexError(message: "\\u braucht vier Hexziffern", position: start)
            }
            value = value * 16 + digit
            index += 1
        }
        return value
    }
}
