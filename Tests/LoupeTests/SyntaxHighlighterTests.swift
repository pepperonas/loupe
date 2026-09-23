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
                try assertFalse(highlighted.contains("<script>"))
                try assertTrue(highlighted.contains("&lt;script&gt;"))
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
