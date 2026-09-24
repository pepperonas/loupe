import Foundation
import LoupeCore

@MainActor
public enum SyntaxHighlighterTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("SyntaxHighlighter") {
            runner.runTest(name: "testSwiftHighlighting") {
                let code = "func greet(name: String) -> Bool { return true }"
                let highlighted = SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: "swift")
                try assertTrue(highlighted.contains("hl-kw"))
                try assertTrue(highlighted.contains("func"))
                try assertTrue(highlighted.contains("hl-type"))
                try assertTrue(highlighted.contains("String"))
            }

            runner.runTest(name: "testSwiftSourceWithManyPrefixChecksCompletes") {
                let line = "public let value: Dictionary<String, Int> = [:]\n"
                let code = String(repeating: line, count: 100)
                let highlighted = SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: "swift")
                try assertTrue(highlighted.contains("hl-kw"))
                try assertTrue(highlighted.contains("Dictionary"))
            }
            
            runner.runTest(name: "testRustHighlighting") {
                let code = "pub fn add(a: i32, b: i32) -> i32 { a + b }"
                let highlighted = SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: "rust")
                try assertTrue(highlighted.contains("hl-kw"))
                try assertTrue(highlighted.contains("pub"))
                try assertTrue(highlighted.contains("fn"))
            }
            
            runner.runTest(name: "testPythonHighlighting") {
                let code = "def test():\n    # A comment\n    return 'success'"
                let highlighted = SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: "python")
                try assertTrue(highlighted.contains("hl-kw"))
                try assertTrue(highlighted.contains("def"))
                try assertTrue(highlighted.contains("hl-com"))
                try assertTrue(highlighted.contains("hl-str"))
            }
            
            runner.runTest(name: "testJavaScriptAndTypeScriptHighlighting") {
                let jsCode = "const handleRequest = async (req, res) => { return res.json({ ok: true }); }"
                let jsHighlighted = SyntaxHighlighter.shared.highlight(code: jsCode, languageIdentifier: "javascript")
                try assertTrue(jsHighlighted.contains("hl-kw"))
                try assertTrue(jsHighlighted.contains("const"))
                try assertTrue(jsHighlighted.contains("async"))
                
                let tsCode = "interface User { id: number; name: string; }"
                let tsHighlighted = SyntaxHighlighter.shared.highlight(code: tsCode, languageIdentifier: "typescript")
                try assertTrue(tsHighlighted.contains("hl-kw"))
                try assertTrue(tsHighlighted.contains("interface"))
            }
            
            runner.runTest(name: "testJavaAndKotlinHighlighting") {
                let javaCode = "public class Main { public static void main(String[] args) {} }"
                let javaHighlighted = SyntaxHighlighter.shared.highlight(code: javaCode, languageIdentifier: "java")
                try assertTrue(javaHighlighted.contains("hl-kw"))
                try assertTrue(javaHighlighted.contains("public"))
                try assertTrue(javaHighlighted.contains("class"))
                
                let ktCode = "data class User(val id: Int, var name: String)"
                let ktHighlighted = SyntaxHighlighter.shared.highlight(code: ktCode, languageIdentifier: "kotlin")
                try assertTrue(ktHighlighted.contains("hl-kw"))
                try assertTrue(ktHighlighted.contains("data"))
                try assertTrue(ktHighlighted.contains("val"))
            }
            
            runner.runTest(name: "testSQLHighlighting") {
                let code = "SELECT name, age FROM users WHERE active = 1"
                let highlighted = SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: "sql")
                try assertTrue(highlighted.contains("hl-kw"))
                try assertTrue(highlighted.contains("SELECT"))
                try assertTrue(highlighted.contains("FROM"))
            }
            
            runner.runTest(name: "testBashHighlighting") {
                let code = "export PATH=\"/usr/local/bin:$PATH\"\necho 'Hello World'\n# A comment"
                let highlighted = SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: "bash")
                try assertTrue(highlighted.contains("hl-kw"))
                try assertTrue(highlighted.contains("export"))
                try assertTrue(highlighted.contains("echo"))
                try assertTrue(highlighted.contains("hl-com"))
                try assertTrue(highlighted.contains("hl-str"))
            }
            
            runner.runTest(name: "testJSONHighlighting") {
                let code = "{\"name\": \"Loupe\", \"version\": 1}"
                let highlighted = SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: "json")
                try assertTrue(highlighted.contains("hl-prop"))
                try assertTrue(highlighted.contains("hl-str"))
                try assertTrue(highlighted.contains("hl-num"))
            }
            
            runner.runTest(name: "testCSSHighlighting") {
                let code = "/* Theme Header */\n.container { color: #ffffff; margin: 10px; }"
                let highlighted = SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: "css")
                try assertTrue(highlighted.contains("hl-com"))
                try assertTrue(highlighted.contains("hl-punc"))
                try assertTrue(highlighted.contains(".container"))
            }
            
            runner.runTest(name: "testBlockComments") {
                let code = "/* multi\nline\ncomment */\nlet x = 1"
                let highlighted = SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: "swift")
                try assertTrue(highlighted.contains("hl-com"))
                try assertTrue(highlighted.contains("/* multi"))
            }
            
            runner.runTest(name: "testEscapesRawHTMLInCode") {
                let code = "<script>alert('test')</script>"
                let highlighted = SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: "html")
                // Eigenschaft statt Formatierung: kein rohes Markup, Text vollstaendig.
                // (Seit dem XML-Tokenizer sind "<", "script" und ">" eigene Tokens.)
                try assertFalse(highlighted.contains("<script>"))
                try assertFalse(highlighted.contains("<script"), "auch kein angefangenes Tag")
                try assertTrue(highlighted.contains("&lt;"))
                try assertEqual(visibleText(highlighted), code)
            }
            
            runner.runTest(name: "testDollarIdentifiersDoNotHang") {
                // Regression: "$" war als Bezeichner-Anfang erlaubt, wurde von der
                // Bezeichner-Schleife aber nicht verbraucht -> Endlosschleife bei
                // Swift-"$0", jQuery-"$(...)" und jedem anderen "$" im Code.
                let cases: [(String, String)] = [
                    ("swift", "items.filter { $0.isActive }.map { $1 }"),
                    ("js", "const el = $('.card'); $el.hide()"),
                    ("kotlin", "val t = \"x\"; println($t)"),
                    ("swift", "$")
                ]
                for (lang, code) in cases {
                    let html = SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: lang)
                    try assertEqual(visibleText(html), code, "\(lang): \(code)")
                }
            }

            runner.runTest(name: "testEveryASCIICharacterTerminatesInEveryLanguage") {
                // Schuetzt die ganze Fehlerklasse: ein Zeichen, das ein Token
                // beginnt, aber nicht verbraucht wird, legt den Tokenizer lahm.
                // Jedes druckbare Zeichen muss durchlaufen UND vollstaendig in der
                // Ausgabe wieder auftauchen.
                let printable = (0x20...0x7E).compactMap { UnicodeScalar($0).map(Character.init) }
                let samples = printable.map { String($0) }
                    + printable.map { "a\($0)b \($0)1 \($0)\($0)" }
                    + ["\t", "\n", "é", "日本", "🚀", "½", "٣"]
                for lang in SupportedLanguage.allCases {
                    for code in samples {
                        let html = SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: lang.rawValue)
                        try assertEqual(visibleText(html), code, "\(lang.rawValue) verliert/verdreht Text in \(code.debugDescription)")
                    }
                }
            }

            runner.runTest(name: "testEmptyAndUnknownLanguageFallback") {
                let empty = SyntaxHighlighter.shared.highlight(code: "", languageIdentifier: nil)
                try assertEqual(empty, "")
                
                let unknownCode = "plain text without highlighting"
                let unknownRes = SyntaxHighlighter.shared.highlight(code: unknownCode, languageIdentifier: nil)
                try assertEqual(unknownRes, unknownCode)
            }
        }
    }
}

/// Sichtbarer Text einer hervorgehobenen Ausgabe: Tags entfernt, Entities aufgeloest.
func visibleText(_ html: String) -> String {
    var out = ""
    var inTag = false
    for ch in html {
        if ch == "<" { inTag = true; continue }
        if ch == ">" && inTag { inTag = false; continue }
        if !inTag { out.append(ch) }
    }
    return out.replacingOccurrences(of: "&lt;", with: "<")
        .replacingOccurrences(of: "&gt;", with: ">")
        .replacingOccurrences(of: "&quot;", with: "\"")
        .replacingOccurrences(of: "&#39;", with: "'")
        .replacingOccurrences(of: "&amp;", with: "&")
}
