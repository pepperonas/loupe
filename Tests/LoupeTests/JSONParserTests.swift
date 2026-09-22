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

            runner.runTest(name: "testLexErrorInTopLevelArrayPreservesItems") {
                // Der Bruch kommt hier aus dem Trailing-Komma-peek() (der das
                // naechste Token lexen muss, um zu pruefen ob es ']' ist),
                // NICHT aus dem rekursiven parseValue-Aufruf fuer das dritte
                // Element -- ein Array ohne umschliessendes Objekt hatte
                // zuvor NICHTS, das diesen Fehler auffing.
                let r = parse(#"[1,2,"\uZZZZ"]"#)
                guard case .failed = r.outcome else {
                    throw TestFailure(message: "haette fehlschlagen muessen", file: #file, line: #line)
                }
                guard case .array(let items, _)? = r.root else {
                    throw TestFailure(message: "kein Array im Teilbaum: \(String(describing: r.root))",
                                       file: #file, line: #line)
                }
                try assertEqual(items.count, 2)
                guard case .number("1") = items[0], case .number("2") = items[1] else {
                    throw TestFailure(message: "Werte falsch", file: #file, line: #line)
                }
            }

            runner.runTest(name: "testArrayNestedInObjectPreservesBothLevels") {
                // Beide Ebenen muessen ueberleben: das Geschwister "a" der
                // Wurzel UND das bereits gelesene Element im kaputten Array
                // unter "b" -- nicht nur eine der beiden.
                let r = parse(#"{"a":1,"b":[9,"\uZZZZ"]}"#)
                guard case .failed = r.outcome else {
                    throw TestFailure(message: "haette fehlschlagen muessen", file: #file, line: #line)
                }
                guard case .object(let members, _)? = r.root else {
                    throw TestFailure(message: "kein Objekt im Teilbaum: \(String(describing: r.root))",
                                       file: #file, line: #line)
                }
                try assertEqual(members.map(\.key), ["a", "b"])
                guard case .number("1") = members[0].value else {
                    throw TestFailure(message: "a falsch", file: #file, line: #line)
                }
                guard case .array(let items, _) = members[1].value else {
                    throw TestFailure(message: "b ist kein Array", file: #file, line: #line)
                }
                try assertEqual(items.count, 1)
                guard case .number("9") = items[0] else {
                    throw TestFailure(message: "b[0] falsch", file: #file, line: #line)
                }
            }

            runner.runTest(name: "testDepthBombDoesNotCrash") {
                // 100.000 Ebenen sind ~100 KB. Ohne Bremse stirbt der Prozess
                // am Stapelueberlauf -- der Test wuerde nicht rot, sondern
                // die ganze Suite abbrechen.
                let deep = String(repeating: "[", count: 100_000)
                let r = parse(deep)
                try assertEqual(r.outcome, .truncatedByLimit(.depth))
            }

            runner.runTest(name: "testDepthLimitIsExactlySixtyFour") {
                func nested(_ n: Int) -> String {
                    String(repeating: "[", count: n) + "1" + String(repeating: "]", count: n)
                }
                try assertEqual(parse(nested(60)).outcome, .complete)
                try assertEqual(parse(nested(200)).outcome, .truncatedByLimit(.depth))
            }

            runner.runTest(name: "testChildrenLimitTruncatesAndCounts") {
                let items = (0 ..< 1500).map(String.init).joined(separator: ",")
                let r = parse("[\(items)]")
                guard case .array(let kept, let omitted)? = r.root else {
                    throw TestFailure(message: "kein Array", file: #file, line: #line)
                }
                try assertEqual(kept.count, 1000)
                // Die Zahl muss STIMMEN -- sie steht spaeter so in der Anzeige.
                try assertEqual(omitted, 500)
                try assertEqual(r.outcome, .truncatedByLimit(.children))
            }

            runner.runTest(name: "testChildrenLimitTruncatesAndCountsObject") {
                // Review-Fund (Finding 2): nur das Array war fuer die exakte
                // omitted-Zahl gepinnt -- wer "omitted += 1" aus parseObjects
                // eigenem Zweig entfernt, blieb bislang unentdeckt (die volle
                // 36er-Suite blieb gruen).
                let members = (0 ..< 1500).map { "\"k\($0)\":\($0)" }.joined(separator: ",")
                let r = parse("{\(members)}")
                guard case .object(let kept, let omitted)? = r.root else {
                    throw TestFailure(message: "kein Objekt", file: #file, line: #line)
                }
                try assertEqual(kept.count, 1000)
                try assertEqual(omitted, 500)
                try assertEqual(r.outcome, .truncatedByLimit(.children))
            }

            runner.runTest(name: "testChildrenLimitAppliesOnFailurePathForArray") {
                // Review-Fund (Finding 1): die Kinder-Grenze wurde nur im
                // GLUECKLICHEN Pfad geprueft. Bricht das 1001. Element selbst
                // (und traegt dabei ein `partial`, weil der Bruch aus einem
                // TIEFEREN Container kommt), nestete der catch es bislang
                // UNGEPRUEFT -- items wuchs auf 1001, omitted blieb 0.
                let good = (0 ..< 1000).map(String.init).joined(separator: ",")
                let r = parse("[\(good),{\"x\":1,\"y\":}]")
                guard case .array(let items, let omitted)? = r.root else {
                    throw TestFailure(message: "kein Array im Teilbaum: \(String(describing: r.root))",
                                       file: #file, line: #line)
                }
                try assertEqual(items.count, 1000)
                try assertEqual(omitted, 1)
                // `noteLimit(.children)` fires as part of handling THIS throw,
                // so failure() reports the limit rather than .failed even
                // though ".y":} is a genuine syntax error -- see task-5-fix-report.md
                // "Finding 1 / a tension surfaced, not asked for" for why this
                // is pinned as the observed behavior rather than silently
                // changed: it's a real design question (which fact wins when
                // both are true of the same file), not something this fix
                // round asked me to resolve.
                try assertEqual(r.outcome, .truncatedByLimit(.children))
            }

            runner.runTest(name: "testChildrenLimitAppliesOnFailurePathForObject") {
                // Objekt-Gegenstueck zu testChildrenLimitAppliesOnFailurePathForArray --
                // derselbe Fund, derselbe Fix, andere Funktion (parseObject statt
                // parseArray), damit beide Catch-Klauseln je einen eigenen Pin haben.
                let good = (0 ..< 1000).map { "\"k\($0)\":\($0)" }.joined(separator: ",")
                let r = parse("{\(good),\"k1000\":{\"x\":1,\"y\":}}")
                guard case .object(let members, let omitted)? = r.root else {
                    throw TestFailure(message: "kein Objekt im Teilbaum: \(String(describing: r.root))",
                                       file: #file, line: #line)
                }
                try assertEqual(members.count, 1000)
                try assertEqual(omitted, 1)
                try assertEqual(r.outcome, .truncatedByLimit(.children))
            }

            runner.runTest(name: "testNodeLimitStopsBuilding") {
                var limits = ParseLimits()
                limits.maxNodes = 50
                let items = (0 ..< 500).map(String.init).joined(separator: ",")
                let r = parse("[\(items)]", limits: limits)
                try assertEqual(r.outcome, .truncatedByLimit(.nodes))
                try assertTrue(r.root != nil, "Teilbaum muss stehen bleiben")
            }

            runner.runTest(name: "testLongStringIsTruncatedForDisplay") {
                // Review-Fund (Finding 4): `assertLessThan(s.count, 100)` liesse
                // eine Regression auf z. B. 50 Zeichen unbemerkt durch -- der
                // exakte Inhalt (Laenge UND Auslassungszeichen) ist der Vertrag.
                var limits = ParseLimits()
                limits.maxStringDisplayLength = 16
                let long = String(repeating: "x", count: 100)
                let r = parse("{\"a\":\"\(long)\"}", limits: limits)
                guard case .object(let members, _)? = r.root,
                      case .string(let s) = members[0].value else {
                    throw TestFailure(message: "Struktur falsch", file: #file, line: #line)
                }
                try assertEqual(s, String(repeating: "x", count: 16) + "…")
                try assertEqual(r.outcome, .truncatedByLimit(.stringLength))
            }

            runner.runTest(name: "testLongObjectKeyIsTruncatedForDisplay") {
                // Review-Fund (Finding 3): maxStringDisplayLength kappte bislang
                // nur WERT-Strings. Ein Schluessel wird dem Nutzer genauso
                // angezeigt wie ein Wert -- dieselbe Grenze muss also fuer
                // beide gelten, mit demselben Auslassungszeichen.
                var limits = ParseLimits()
                limits.maxStringDisplayLength = 16
                let longKey = String(repeating: "k", count: 9000)
                let r = parse("{\"\(longKey)\":1}", limits: limits)
                guard case .object(let members, _)? = r.root else {
                    throw TestFailure(message: "kein Objekt", file: #file, line: #line)
                }
                try assertEqual(members[0].key, String(repeating: "k", count: 16) + "…")
                try assertEqual(r.outcome, .truncatedByLimit(.stringLength))
            }

            runner.runTest(name: "testTruncationIsNotReportedAsFailure") {
                // Eine GUELTIGE Datei, die WIR gekuerzt haben, darf nie als
                // kaputt erscheinen. Sonst luegt die Vorschau ueber die Datei.
                let r = parse(#"{"a":1,"b"#, truncated: true)
                guard case .truncatedByLimit = r.outcome else {
                    throw TestFailure(message: "als Fehler gemeldet statt als Kuerzung",
                                      file: #file, line: #line)
                }
                try assertFalse(r.diagnostics.contains { $0.severity == .error },
                                "Kuerzung darf keine Fehlermeldung erzeugen")
            }

            runner.runTest(name: "testMissingCommaInNestedObjectNestsPartialUnderAncestorKey") {
                // Luecke aus Task 4: der geweitete catch in parseObject war fuer
                // NICHT-Wert-Wurfstellen (Schluessel/Doppelpunkt/Komma) in einem
                // VERSCHACHTELTEN Objekt nicht mutationsgeprueft -- nur der
                // Wert-Wurfpfad (ueber parseValue, siehe
                // testAncestorSiblingsSurviveNestedFailure) hatte einen Pin.
                // Ein fehlendes Komma im INNEREN Objekt (Wurfstelle liegt beim
                // Trenner-advance(), NICHT im rekursiven parseValue-Aufruf) muss
                // trotzdem als Teilbaum unter dem AEUSSEREN Schluessel auftauchen
                // -- sowohl die Daten des inneren Objekts als auch dessen
                // Zuordnung zu "outer" muessen erhalten bleiben.
                let r = parse(#"{"outer":{"a":1 "b":2}}"#)
                guard case .failed = r.outcome else {
                    throw TestFailure(message: "haette fehlschlagen muessen", file: #file, line: #line)
                }
                guard case .object(let outerMembers, _)? = r.root else {
                    throw TestFailure(message: "kein Objekt im Teilbaum: \(String(describing: r.root))",
                                       file: #file, line: #line)
                }
                try assertEqual(outerMembers.map(\.key), ["outer"])
                guard case .object(let innerMembers, _) = outerMembers[0].value else {
                    throw TestFailure(message: "outer-Wert ist kein genestetes Objekt",
                                       file: #file, line: #line)
                }
                try assertEqual(innerMembers.map(\.key), ["a"])
                guard case .number("1") = innerMembers[0].value else {
                    throw TestFailure(message: "a falsch", file: #file, line: #line)
                }
            }
        }
    }
}
