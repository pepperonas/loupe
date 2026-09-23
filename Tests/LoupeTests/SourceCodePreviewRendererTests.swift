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
