import Foundation
import LoupeCore

@MainActor
public enum SourceCodePreviewRendererTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("SourceCodePreviewRenderer") {
            runner.runTest(name: "testBasicSwiftRendering") {
                let code = """
                import Foundation

                func hello(name: String) -> String {
                    return "Hello, \\(name)!"
                }
                """
                let url = URL(fileURLWithPath: "/tmp/hello.swift")
                let input = PreviewInput(data: Data(code.utf8), url: url, wasTruncatedByReader: false)
                let renderer = SourceCodePreviewRenderer()
                let settings = LoupeSettings()
                let html = renderer.renderHTML(input: input, settings: settings)

                try assertTrue(html.contains("<table class=\"lp-code-table\">"))
                try assertTrue(html.contains("<td class=\"lp-line-no\">1</td>"))
                try assertTrue(html.contains("<td class=\"lp-line-no\">5</td>"))
                try assertTrue(html.contains("hl-kw"))
                try assertTrue(html.contains("func"))
                try assertTrue(html.contains("hello.swift"))
                try assertTrue(html.contains("Swift"))
                try assertTrue(html.contains("5 Zeilen"))
            }

            runner.runTest(name: "testTrailingNewlineAddsNoPhantomLine") {
                // Eine Datei mit abschliessendem Zeilenumbruch hat so viele Zeilen wie
                // "wc -l" zaehlt -- nicht eine leere mehr.
                func render(_ code: String) -> String {
                    SourceCodePreviewRenderer().renderHTML(
                        input: PreviewInput(data: Data(code.utf8), url: URL(fileURLWithPath: "/tmp/a.swift"),
                                            wasTruncatedByReader: false),
                        settings: LoupeSettings())
                }
                let lf = render("let a = 1\nlet b = 2\n")
                try assertTrue(lf.contains("2 Zeilen"), "LF")
                try assertFalse(lf.contains(#"<td class="lp-line-no">3</td>"#), "keine Phantomzeile 3")
                let crlf = render("let a = 1\r\nlet b = 2\r\n")
                try assertTrue(crlf.contains("2 Zeilen"), "CRLF")
                let noEOL = render("let a = 1\nlet b = 2")
                try assertTrue(noEOL.contains("2 Zeilen"), "ohne Umbruch am Ende")
                let blankLast = render("let a = 1\n\n")
                try assertTrue(blankLast.contains("2 Zeilen"), "eine echte Leerzeile am Ende bleibt")
                try assertTrue(render("").contains("1 Zeile"), "leere Datei")
            }

            runner.runTest(name: "testPythonRendering") {
                let code = """
                def calculate(x, y):
                    # compute sum
                    return x + y
                """
                let url = URL(fileURLWithPath: "/tmp/calc.py")
                let input = PreviewInput(data: Data(code.utf8), url: url, wasTruncatedByReader: false)
                let renderer = SourceCodePreviewRenderer()
                let html = renderer.renderHTML(input: input, settings: LoupeSettings())

                try assertTrue(html.contains("calc.py"))
                try assertTrue(html.contains("Python"))
                try assertTrue(html.contains("hl-kw"))
                try assertTrue(html.contains("def"))
                try assertTrue(html.contains("hl-com"))
                try assertTrue(html.contains("compute sum"))
                try assertTrue(html.contains("3 Zeilen"))
            }

            runner.runTest(name: "testRustRendering") {
                let code = "pub fn add(a: i32, b: i32) -> i32 {\n    a + b\n}"
                let url = URL(fileURLWithPath: "/tmp/lib.rs")
                let input = PreviewInput(data: Data(code.utf8), url: url, wasTruncatedByReader: false)
                let renderer = SourceCodePreviewRenderer()
                let html = renderer.renderHTML(input: input, settings: LoupeSettings())

                try assertTrue(html.contains("lib.rs"))
                try assertTrue(html.contains("Rust"))
                try assertTrue(html.contains("hl-kw"))
                try assertTrue(html.contains("pub"))
            }

            runner.runTest(name: "testTypeScriptRendering") {
                let code = "interface Greeter {\n    greet(msg: string): void;\n}"
                let url = URL(fileURLWithPath: "/tmp/app.ts")
                let input = PreviewInput(data: Data(code.utf8), url: url, wasTruncatedByReader: false)
                let renderer = SourceCodePreviewRenderer()
                let html = renderer.renderHTML(input: input, settings: LoupeSettings())

                try assertTrue(html.contains("app.ts"))
                try assertTrue(html.contains("TypeScript"))
                try assertTrue(html.contains("interface"))
            }

            runner.runTest(name: "testHTMLSanitization") {
                let code = "const x = \"<script>alert('xss')</script>\";"
                let url = URL(fileURLWithPath: "/tmp/danger.js")
                let input = PreviewInput(data: Data(code.utf8), url: url, wasTruncatedByReader: false)
                let renderer = SourceCodePreviewRenderer()
                let html = renderer.renderHTML(input: input, settings: LoupeSettings())

                try assertFalse(html.contains("<script>alert"))
                try assertTrue(html.contains("&lt;script&gt;"))
            }

            runner.runTest(name: "testEmptyCodeFile") {
                let url = URL(fileURLWithPath: "/tmp/empty.sh")
                let input = PreviewInput(data: Data(), url: url, wasTruncatedByReader: false)
                let renderer = SourceCodePreviewRenderer()
                let html = renderer.renderHTML(input: input, settings: LoupeSettings())

                try assertTrue(html.contains("empty.sh"))
                try assertTrue(html.contains("Shell"))
                try assertTrue(html.contains("1 Zeile"))
            }

            runner.runTest(name: "testTruncationBanner") {
                let code = "let x = 1\n"
                let url = URL(fileURLWithPath: "/tmp/huge.swift")
                let input = PreviewInput(data: Data(code.utf8), url: url, wasTruncatedByReader: true)
                let renderer = SourceCodePreviewRenderer()
                let html = renderer.renderHTML(input: input, settings: LoupeSettings())

                try assertTrue(html.contains("lp-banner-notice"))
                try assertTrue(html.contains("Vorschau gekürzt"))
            }

            runner.runTest(name: "testZeroJavaScriptInOutput") {
                let code = "function test() { console.log('hello'); }"
                let url = URL(fileURLWithPath: "/tmp/test.js")
                let input = PreviewInput(data: Data(code.utf8), url: url, wasTruncatedByReader: false)
                let renderer = SourceCodePreviewRenderer()
                let html = renderer.renderHTML(input: input, settings: LoupeSettings())

                try assertFalse(html.contains("<script"))
                try assertFalse(html.contains("javascript:"))
            }
        }
    }
}
