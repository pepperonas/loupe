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
                // Der Zeiger muss trotz Klippung auf die richtige Stelle zeigen ("1").
                try assertTrue(lines[0].caretColumn != nil, "caretColumn should not be nil")
                try assertLessThan(lines[0].caretColumn!, lines[0].text.count + 1)
                let caretCol = lines[0].caretColumn!
                let caretPos = caretCol - 1
                let text = lines[0].text
                let idx = text.index(text.startIndex, offsetBy: caretPos)
                try assertTrue(idx < text.endIndex, "caret position out of bounds")
                try assertEqual(String(text[idx]), "1")
            }

            runner.runTest(name: "testTabsBecomeSpacesSoCaretAligns") {
                // Ein Tab ist EIN Zeichen, wird aber breit dargestellt --
                // der Zeiger stuende sonst falsch.
                let lines = SourceExcerpt.make(bytes: Array("\t\tx".utf8),
                                               around: Position(line: 1, column: 3, offset: 0),
                                               contextLines: 0)
                try assertFalse(lines[0].text.contains("\t"))
                // Der Zeiger muss auf 'x' zeigen (Spalte 9 nach Expansion), nicht auf ein Leerzeichen.
                try assertTrue(lines[0].caretColumn != nil, "caretColumn should not be nil")
                let caretCol = lines[0].caretColumn!
                try assertEqual(caretCol, 9)
                let text = lines[0].text
                let caretPos = caretCol - 1
                let idx = text.index(text.startIndex, offsetBy: caretPos)
                try assertTrue(idx < text.endIndex, "caret position out of bounds")
                try assertEqual(String(text[idx]), "x")
            }

            // Test pins for 4 measured cases (byte vs character indexing)
            runner.runTest(name: "testTabsPin_TwoTabsAndX") {
                // Column 3 is the third byte: second tab ends at byte 2, third byte
                // is the 'x'. After tab expansion (4 spaces each), x is at column 9.
                let lines = SourceExcerpt.make(bytes: Array("\t\tx".utf8),
                                               around: Position(line: 1, column: 3, offset: 0),
                                               contextLines: 0)
                try assertTrue(lines[0].caretColumn != nil, "caretColumn should not be nil")
                let caretCol = lines[0].caretColumn!
                try assertEqual(caretCol, 9)
                let text = lines[0].text
                let caretPos = caretCol - 1
                let idx = text.index(text.startIndex, offsetBy: caretPos)
                try assertTrue(idx < text.endIndex, "caret position out of bounds")
                try assertEqual(String(text[idx]), "x")
            }

            runner.runTest(name: "testEmojiPin_FireAndX") {
                // "🎉x" - emoji 🎉 is 4 bytes, x is at byte 5 (column 5).
                // In characters, 🎉 is 1 character, so x is at character 2.
                let lines = SourceExcerpt.make(bytes: Array("🎉x".utf8),
                                               around: Position(line: 1, column: 5, offset: 0),
                                               contextLines: 0)
                try assertTrue(lines[0].caretColumn != nil, "caretColumn should not be nil")
                let caretCol = lines[0].caretColumn!
                try assertEqual(caretCol, 2)
                let text = lines[0].text
                let caretPos = caretCol - 1
                let idx = text.index(text.startIndex, offsetBy: caretPos)
                try assertTrue(idx < text.endIndex, "caret position out of bounds")
                try assertEqual(String(text[idx]), "x")
            }

            runner.runTest(name: "testUmlautPin_GrueseAndX") {
                // "\"grüße\":x" - ü is 2 bytes, ß is 2 bytes.
                // 10 bytes precede 'x' ("\"grüße\":"), so 'x' is at byte 11.
                // In characters: 8 characters precede 'x', so 'x' is at character 9.
                let text = "\"grüße\":x"
                let lines = SourceExcerpt.make(bytes: Array(text.utf8),
                                               around: Position(line: 1, column: 11, offset: 0),
                                               contextLines: 0)
                try assertTrue(lines[0].caretColumn != nil, "caretColumn should not be nil")
                let caretCol = lines[0].caretColumn!
                try assertEqual(caretCol, 9)
                let resultText = lines[0].text
                let caretPos = caretCol - 1
                let idx = resultText.index(resultText.startIndex, offsetBy: caretPos)
                try assertTrue(idx < resultText.endIndex, "caret position out of bounds")
                try assertEqual(String(resultText[idx]), "x")
            }

            runner.runTest(name: "testASCIIPin_ABCAndX") {
                // "abcx" - all ASCII, byte 4 is 'x', character 4 is 'x'
                let lines = SourceExcerpt.make(bytes: Array("abcx".utf8),
                                               around: Position(line: 1, column: 4, offset: 0),
                                               contextLines: 0)
                try assertTrue(lines[0].caretColumn != nil, "caretColumn should not be nil")
                let caretCol = lines[0].caretColumn!
                try assertEqual(caretCol, 4)
                let text = lines[0].text
                let caretPos = caretCol - 1
                let idx = text.index(text.startIndex, offsetBy: caretPos)
                try assertTrue(idx < text.endIndex, "caret position out of bounds")
                try assertEqual(String(text[idx]), "x")
            }

            // Test untested branches
            runner.runTest(name: "testErrorOnLastLineWithContext") {
                // Error on last line with contextLines reaching past EOF
                let lines = SourceExcerpt.make(bytes: Array("line1\nline2".utf8),
                                               around: Position(line: 2, column: 3, offset: 0),
                                               contextLines: 5)
                try assertEqual(lines.map(\.number), [1, 2])
            }

            runner.runTest(name: "testLongContextLineWithCentre1Clipping") {
                // Long context line that forces centre = 1 clipping path
                let longLine = String(repeating: "x", count: 300)
                let lines = SourceExcerpt.make(bytes: Array(longLine.utf8),
                                               around: Position(line: 1, column: 1, offset: 0),
                                               contextLines: 0)
                try assertLessThan(lines[0].text.count, 400)
                // Caret should be at the beginning
                try assertEqual(lines[0].caretColumn, 1)
            }
        }
    }
}
