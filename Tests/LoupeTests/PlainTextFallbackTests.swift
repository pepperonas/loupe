import Foundation
import LoupeCore

/// Abgeschaltet muss Loupe Rohtext liefern wie macOS ohne Loupe -- eine
/// Absage liess Quick Look nur die Datei-Karte zeigen (gemessen 2026-09-26).
@MainActor
public enum PlainTextFallbackTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("PlainTextFallback") {

            runner.runTest(name: "testUTF8IsPassedThroughUnchanged") {
                let s = "{\n  \"name\": \"Grüße ✓ 🙂\"\n}\n"
                try assertEqual(PlainTextFallback.text(from: Data(s.utf8)), s)
            }

            runner.runTest(name: "testUTF8BOMIsDropped") {
                let d = Data([0xEF, 0xBB, 0xBF]) + Data("abc".utf8)
                try assertEqual(PlainTextFallback.text(from: d), "abc")
            }

            runner.runTest(name: "testUTF16WithBOMIsDecoded") {
                var d = Data([0xFF, 0xFE]) // little endian, typisch fuer PowerShell-Dateien
                d.append("Write-Host 'hi'".data(using: .utf16LittleEndian)!)
                try assertEqual(PlainTextFallback.text(from: d), "Write-Host 'hi'")
                var be = Data([0xFE, 0xFF])
                be.append("ok".data(using: .utf16BigEndian)!)
                try assertEqual(PlainTextFallback.text(from: be), "ok")
            }

            runner.runTest(name: "testInvalidUTF8FallsBackToLatin1") {
                // Windows-/Altdateien: kein Zeichen darf verloren gehen.
                let d = Data([0x47, 0x72, 0xFC, 0xDF, 0x65]) // "Grüße" in Latin-1
                try assertEqual(PlainTextFallback.text(from: d), "Grüße")
            }

            runner.runTest(name: "testUTF8CutMidCharacterKeepsTheRest") {
                // Das Lesen endet an einer Bytegrenze, evtl. mitten in einem Zeichen.
                var d = Data("Grüße".utf8)
                d.append(contentsOf: [0xF0, 0x9F]) // halbes Emoji
                let t = PlainTextFallback.text(from: d)
                try assertTrue(t.hasPrefix("Grüße"), t)
            }

            runner.runTest(name: "testEmptyStaysEmpty") {
                try assertEqual(PlainTextFallback.text(from: Data()), "")
            }
        }
    }
}
