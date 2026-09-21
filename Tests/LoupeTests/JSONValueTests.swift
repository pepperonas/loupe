import Foundation
import LoupeCore

@MainActor
public enum JSONValueTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("JSONValue") {

            runner.runTest(name: "testObjectPreservesMemberOrder") {
                let obj = JSONValue.object(members: [
                    Member(key: "zebra", value: .number("1")),
                    Member(key: "alpha", value: .number("2"))
                ], omitted: 0)
                guard case .object(let members, _) = obj else {
                    throw TestFailure(message: "kein Objekt", file: #file, line: #line)
                }
                // Die Reihenfolge der Datei, NICHT alphabetisch.
                try assertEqual(members.map(\.key), ["zebra", "alpha"])
            }

            runner.runTest(name: "testObjectKeepsDuplicateKeys") {
                let obj = JSONValue.object(members: [
                    Member(key: "a", value: .number("1")),
                    Member(key: "a", value: .number("2"))
                ], omitted: 0)
                guard case .object(let members, _) = obj else {
                    throw TestFailure(message: "kein Objekt", file: #file, line: #line)
                }
                // Ein Dictionary haette den ersten still verworfen.
                try assertEqual(members.count, 2)
                try assertEqual(members.map(\.key), ["a", "a"])
            }

            runner.runTest(name: "testNumberKeepsSourceSpelling") {
                // 1.0 darf NICHT zu 1 werden, 1e400 nicht zu inf,
                // grosse Ganzzahlen duerfen keine Stellen verlieren.
                let cases = ["1.0", "1e400", "9007199254740993", "-0"]
                for raw in cases {
                    guard case .number(let text) = JSONValue.number(raw) else {
                        throw TestFailure(message: "keine Zahl", file: #file, line: #line)
                    }
                    try assertEqual(text, raw)
                }
            }

            runner.runTest(name: "testPositionIsOneBased") {
                let p = Position(line: 1, column: 1, offset: 0)
                try assertEqual(p.line, 1)
                try assertEqual(p.column, 1)
                try assertEqual(p.offset, 0)
            }

            runner.runTest(name: "testOutcomeDistinguishesTruncationFromFailure") {
                // Die wichtigste Unterscheidung des ganzen Projekts:
                // WIR haben gekuerzt ist nicht dasselbe wie die DATEI ist kaputt.
                let a = ParseOutcome.truncatedByLimit(.bytes)
                let b = ParseOutcome.failed(at: Position(line: 1, column: 1, offset: 0))
                try assertFalse(a == b)
            }
        }
    }
}
