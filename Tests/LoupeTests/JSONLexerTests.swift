import Foundation
import LoupeCore

@MainActor
public enum JSONLexerTests {

    private static func tokens(_ text: String) throws -> [TokenKind] {
        var lexer = JSONLexer(bytes: Array(text.utf8))
        var out: [TokenKind] = []
        while true {
            let token = try lexer.next()
            if token.kind == .endOfInput { break }
            out.append(token.kind)
        }
        return out
    }

    public static func run() {
        let runner = TestRunner.shared
        runner.suite("JSONLexer") {

            runner.runTest(name: "testStructuralTokens") {
                try assertEqual(try tokens("{}[],:"),
                                [.braceOpen, .braceClose, .bracketOpen, .bracketClose, .comma, .colon])
            }

            runner.runTest(name: "testLiterals") {
                try assertEqual(try tokens("true false null"),
                                [.literalTrue, .literalFalse, .literalNull])
            }

            runner.runTest(name: "testNumbersKeepSourceSpelling") {
                try assertEqual(try tokens("1.0"), [.number("1.0")])
                try assertEqual(try tokens("-0"), [.number("-0")])
                try assertEqual(try tokens("1e400"), [.number("1e400")])
                try assertEqual(try tokens("9007199254740993"), [.number("9007199254740993")])
            }

            runner.runTest(name: "testLeadingZeroIsInvalid") {
                // JSON verbietet fuehrende Nullen. 01 ist KEINE gueltige Zahl.
                var threw = false
                do { _ = try tokens("01") } catch { threw = true }
                try assertTrue(threw, "01 muss abgelehnt werden")
            }

            runner.runTest(name: "testStringEscapes") {
                try assertEqual(try tokens("\"a\\\"b\""), [.string("a\"b")])
                try assertEqual(try tokens("\"\\n\\t\\\\\""), [.string("\n\t\\")])
                try assertEqual(try tokens("\"\\/\""), [.string("/")])
            }

            runner.runTest(name: "testUnicodeEscapeAndSurrogatePair") {
                try assertEqual(try tokens("\"\\u00e4\""), [.string("ä")])
                // U+1F600, als Surrogatpaar geschrieben -- muss zu EINEM Zeichen werden.
                try assertEqual(try tokens("\"\\ud83d\\ude00\""), [.string("😀")])
            }

            runner.runTest(name: "testLoneSurrogateDoesNotCrash") {
                // Ein einzelnes hohes Surrogat ist kein gueltiger Skalar.
                // Erwartung: sauberer Fehler, KEIN Absturz.
                var threw = false
                do { _ = try tokens("\"\\ud83d\"") } catch { threw = true }
                try assertTrue(threw, "einzelnes Surrogat muss einen Fehler geben")
            }

            runner.runTest(name: "testPositionsAreOneBasedAndCountLines") {
                var lexer = JSONLexer(bytes: Array("{\n  \"a\"".utf8))
                let brace = try lexer.next()
                try assertEqual(brace.position.line, 1)
                try assertEqual(brace.position.column, 1)
                let key = try lexer.next()
                try assertEqual(key.position.line, 2)
                try assertEqual(key.position.column, 3)
            }

            runner.runTest(name: "testUnterminatedStringReportsPosition") {
                var lexer = JSONLexer(bytes: Array("\"abc".utf8))
                do {
                    _ = try lexer.next()
                    throw TestFailure(message: "haette werfen muessen", file: #file, line: #line)
                } catch let e as LexError {
                    try assertEqual(e.position.line, 1)
                } 
            }

            runner.runTest(name: "testByteOrderMarkIsSkipped") {
                // Viele Werkzeuge schreiben ein BOM. Es ist kein Fehler.
                try assertEqual(try tokens("\u{FEFF}{}"), [.braceOpen, .braceClose])
            }
        }
    }
}
