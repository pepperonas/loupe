import Foundation
import LoupeCore

@MainActor
public enum HTMLEscapeTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("HTMLEscape") {

            runner.runTest(name: "testEscapesAllFiveDangerousCharacters") {
                try assertEqual(HTMLEscape.escape("&"), "&amp;")
                try assertEqual(HTMLEscape.escape("<"), "&lt;")
                try assertEqual(HTMLEscape.escape(">"), "&gt;")
                try assertEqual(HTMLEscape.escape("\""), "&quot;")
                try assertEqual(HTMLEscape.escape("'"), "&#39;")
            }

            runner.runTest(name: "testAmpersandEscapedFirst") {
                // Wuerde & zuletzt ersetzt, entstuende aus < erst &lt; und
                // daraus &amp;lt; -- sichtbarer Muell.
                try assertEqual(HTMLEscape.escape("<a>"), "&lt;a&gt;")
            }

            runner.runTest(name: "testScriptInJSONStringIsNeutralised") {
                // Ein JSON-String DARF <script> enthalten. Escaped ist er Text.
                let out = HTMLEscape.escape("<script>alert(1)</script>")
                try assertFalse(out.contains("<script"))
                try assertTrue(out.contains("&lt;script&gt;"))
            }

            runner.runTest(name: "testUnicodeAndEmojiSurviveUnchanged") {
                try assertEqual(HTMLEscape.escape("äöü 😀 日本語"), "äöü 😀 日本語")
            }
        }
    }
}
