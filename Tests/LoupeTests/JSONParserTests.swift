import Foundation
import LoupeCore

@MainActor
public enum JSONParserTests {

    static func parse(_ text: String,
                      limits: ParseLimits = ParseLimits(),
                      truncated: Bool = false) -> ParseResult {
        var parser = JSONParser(bytes: Array(text.utf8), limits: limits,
                                wasTruncatedByReader: truncated)
        return parser.parse()
    }

    static func keys(_ value: JSONValue?) throws -> [String] {
        guard case .object(let members, _)? = value else {
            throw TestFailure(message: "kein Objekt", file: #file, line: #line)
        }
        return members.map(\.key)
    }

    public static func run() {
        let runner = TestRunner.shared
        runner.suite("JSONParser") {

            runner.runTest(name: "testKeyOrderIsSourceOrder") {
                // DER Test des Projekts. Faellt er, luegt das Produkt.
                let r = parse(#"{"zebra":1,"alpha":2,"mitte":3}"#)
                try assertEqual(r.outcome, .complete)
                try assertEqual(try keys(r.root), ["zebra", "alpha", "mitte"])
            }

            runner.runTest(name: "testDuplicateKeysBothSurvive") {
                let r = parse(#"{"a":1,"a":2}"#)
                try assertEqual(try keys(r.root), ["a", "a"])
            }

            runner.runTest(name: "testNestedStructure") {
                let r = parse(#"{"a":{"b":[1,"x",null,true]}}"#)
                guard case .object(let outer, _)? = r.root,
                      case .object(let inner, _) = outer[0].value,
                      case .array(let items, _) = inner[0].value else {
                    throw TestFailure(message: "Struktur falsch", file: #file, line: #line)
                }
                try assertEqual(items.count, 4)
                guard case .number("1") = items[0], case .string("x") = items[1],
                      case .null = items[2], case .bool(true) = items[3] else {
                    throw TestFailure(message: "Werte falsch", file: #file, line: #line)
                }
            }

            runner.runTest(name: "testBareScalarIsValidJSON") {
                // 42 allein ist gueltiges JSON (RFC 8259).
                try assertEqual(parse("42").outcome, .complete)
                try assertEqual(parse(#""hallo""#).outcome, .complete)
                try assertEqual(parse("null").outcome, .complete)
            }

            runner.runTest(name: "testEmptyContainers") {
                let r = parse(#"{"a":{},"b":[]}"#)
                try assertEqual(r.outcome, .complete)
            }

            runner.runTest(name: "testEmptyInputFails") {
                guard case .failed = parse("").outcome else {
                    throw TestFailure(message: "leere Datei muss fehlschlagen", file: #file, line: #line)
                }
            }

            runner.runTest(name: "testMissingCommaReportsPosition") {
                let r = parse("{\n  \"a\": 1\n  \"b\": 2\n}")
                guard case .failed(let at) = r.outcome else {
                    throw TestFailure(message: "haette fehlschlagen muessen", file: #file, line: #line)
                }
                try assertEqual(at.line, 3)
            }

            runner.runTest(name: "testPartialTreeSurvivesFailure") {
                // Kern der Fehlertoleranz: was bis zum Bruch gelesen wurde,
                // muss erhalten bleiben -- sonst zeigt die Vorschau nichts.
                let r = parse(#"{"gut":1,"kaputt":}"#)
                guard case .failed = r.outcome else {
                    throw TestFailure(message: "haette fehlschlagen muessen", file: #file, line: #line)
                }
                try assertTrue(r.root != nil, "Teilbaum muss erhalten bleiben")
                try assertTrue(try keys(r.root).contains("gut"))
            }

            runner.runTest(name: "testTrailingContentHintsAtJSONLines") {
                let r = parse("{\"a\":1}\n{\"b\":2}")
                guard case .failed = r.outcome else {
                    throw TestFailure(message: "haette fehlschlagen muessen", file: #file, line: #line)
                }
                let text = r.diagnostics.map(\.message).joined(separator: " ")
                try assertTrue(text.contains("JSON Lines"),
                               "Hinweis auf JSON Lines fehlt: \(text)")
            }

            runner.runTest(name: "testLexErrorPreservesPartialTree") {
                // Ein Fehler auf Lexer-Ebene (kaputtes \u-Escape) darf den
                // bereits gelesenen Teilbaum nicht mitreissen. Das ist sogar
                // der HAEUFIGERE Fall als ein ParseError: ein abgeschnittener
                // Bytestrom bricht fast immer MITTEN in einem Token
                // (String/Zahl), nie sauber zwischen zwei Token.
                let r = parse(#"{"good":1,"bad":"\uZZZZ"}"#)
                guard case .failed = r.outcome else {
                    throw TestFailure(message: "haette fehlschlagen muessen", file: #file, line: #line)
                }
                try assertTrue(r.root != nil, "Teilbaum muss auch bei einem LexError erhalten bleiben")
                try assertTrue(try keys(r.root).contains("good"))
            }

            runner.runTest(name: "testAncestorSiblingsSurviveNestedFailure") {
                // Ein Bruch zwei Ebenen tief darf nicht nur den innersten
                // Teilbaum zeigen -- alle bereits gelesenen Geschwister auf
                // dem Weg zur Wurzel muessen erhalten bleiben, nicht nur die
                // des Containers, in dem der Bruch selbst liegt.
                let r = parse(#"{"first":1,"second":{"nested":"good","broken":},"third":3}"#)
                guard case .failed = r.outcome else {
                    throw TestFailure(message: "haette fehlschlagen muessen", file: #file, line: #line)
                }
                try assertTrue(try keys(r.root).contains("first"),
                               "Geschwister vor dem verschachtelten Bruch muss erhalten bleiben")
            }

            runner.runTest(name: "testTruncatedMidTokenReportsTruncationNotFailure") {
                // Der Fall, um den es bei wasTruncatedByReader/maxBytes
                // eigentlich geht: eine Kuerzung reisst fast immer MITTEN in
                // einem Token ab (hier: eine nicht geschlossene
                // Zeichenkette) -- ein LexError, kein ParseError. Mit
                // truncated:true darf das NICHT als Dateifehler erscheinen.
                let r = parse(#"{"a":"unterminat"#, truncated: true)
                guard case .truncatedByLimit(let kind) = r.outcome else {
                    throw TestFailure(message: "haette als truncatedByLimit erscheinen muessen, war \(r.outcome)",
                                       file: #file, line: #line)
                }
                try assertEqual(kind, .bytes)
                try assertTrue(!r.diagnostics.contains { $0.severity == .error },
                               "kein .error-Diagnostic bei einer Kuerzung")
            }
        }
    }
}
