import Foundation
import LoupeCore

@MainActor
public enum SourceExcerptTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("SourceExcerpt") {

            runner.runTest(name: "testExcerptShowsContextAndCaret") {
                let src = "{\n  \"version\": \"1.0.0\"\n  \"private\": true\n}"
                let lines = SourceExcerpt.make(bytes: Array(src.utf8),
                                               around: Position(line: 3, column: 3, offset: 0),
                                               contextLines: 1)
                // contextLines is symmetric: show 1 line before and after, like grep -C
                try assertEqual(lines.map(\.number), [2, 3, 4])
                try assertEqual(lines[1].caretColumn, 3)
                try assertEqual(lines[0].caretColumn, nil)
                try assertTrue(lines[1].text.contains("private"))
            }

            runner.runTest(name: "testExcerptAtFirstLineDoesNotUnderflow") {
                let lines = SourceExcerpt.make(bytes: Array("{}".utf8),
                                               around: Position(line: 1, column: 1, offset: 0),
                                               contextLines: 2)
                try assertEqual(lines.map(\.number), [1])
            }

            runner.runTest(name: "testVeryLongLineIsClipped") {
                // Eine minifizierte JSON-Datei ist EINE Zeile mit Millionen
                // Zeichen. Ungeklippt legt sie das Fehlerbanner lahm.
                let long = "{\"a\":" + String(repeating: "1", count: 5000) + "}"
                let lines = SourceExcerpt.make(bytes: Array(long.utf8),
                                               around: Position(line: 1, column: 4000, offset: 0),
                                               contextLines: 0)
                try assertLessThan(lines[0].text.count, 400)
                // Der Zeiger muss trotz Klippung auf die richtige Stelle zeigen.
                try assertTrue(lines[0].caretColumn != nil)
                try assertLessThan(lines[0].caretColumn!, lines[0].text.count + 1)
            }

            runner.runTest(name: "testTabsBecomeSpacesSoCaretAligns") {
                // Ein Tab ist EIN Zeichen, wird aber breit dargestellt --
                // der Zeiger stuende sonst falsch.
                let lines = SourceExcerpt.make(bytes: Array("\t\tx".utf8),
                                               around: Position(line: 1, column: 3, offset: 0),
                                               contextLines: 0)
                try assertFalse(lines[0].text.contains("\t"))
            }
        }
    }
}
