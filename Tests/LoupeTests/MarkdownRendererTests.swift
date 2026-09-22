import Foundation
import LoupeCore

@MainActor
public enum MarkdownRendererTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("MarkdownRenderer") {
            runner.runTest(name: "testBasicMarkdownRendering") {
                let md = """
                # My Document
                
                This is a paragraph with **bold** and *italic* text.
                
                - Item 1
                - Item 2
                """
                let renderer = MarkdownRenderer()
                let html = renderer.renderHTML(markdown: md)
                
                try assertTrue(html.contains("<h1 id=\"my-document\">My Document</h1>"))
                try assertTrue(html.contains("<strong>bold</strong>"))
                try assertTrue(html.contains("<em>italic</em>"))
                try assertTrue(html.contains("<ul>"))
                try assertTrue(html.contains("<li>Item 1</li>"))
            }
            
            runner.runTest(name: "testHeadingsLevels") {
                let md = """
                # H1
                ## H2
                ### H3
                #### H4
                ##### H5
                ###### H6
                """
                let renderer = MarkdownRenderer()
                let html = renderer.renderHTML(markdown: md)
                
                try assertTrue(html.contains("<h1 id=\"h1\">H1</h1>"))
                try assertTrue(html.contains("<h2 id=\"h2\">H2</h2>"))
                try assertTrue(html.contains("<h3 id=\"h3\">H3</h3>"))
                try assertTrue(html.contains("<h4 id=\"h4\">H4</h4>"))
                try assertTrue(html.contains("<h5 id=\"h5\">H5</h5>"))
                try assertTrue(html.contains("<h6 id=\"h6\">H6</h6>"))
            }
            
            runner.runTest(name: "testHeadingAnchorSlugGeneration") {
                let md = "# Welcome to Loupe: The Best Preview (v1.0)!"
                let renderer = MarkdownRenderer()
                let html = renderer.renderHTML(markdown: md)
                try assertTrue(html.contains("id=\"welcome-to-loupe-the-best-preview-v1-0\""))
            }
            
            runner.runTest(name: "testInlineCodeRendering") {
                let md = "Here is `let a = \"hello & world\"` in code."
                let renderer = MarkdownRenderer()
                let html = renderer.renderHTML(markdown: md)
                try assertTrue(html.contains("<code>let a = &quot;hello &amp; world&quot;</code>"))
            }
            
            runner.runTest(name: "testStrikethroughRendering") {
                let md = "This is ~~deprecated code~~."
                let renderer = MarkdownRenderer()
                let html = renderer.renderHTML(markdown: md)
                try assertTrue(html.contains("<del>deprecated code</del>"))
            }
            
            runner.runTest(name: "testThematicBreakRendering") {
                let md = "Above\n\n---\n\nBelow"
                let renderer = MarkdownRenderer()
                let html = renderer.renderHTML(markdown: md)
                try assertTrue(html.contains("<hr>"))
            }
            
            runner.runTest(name: "testLinkWithTitleAndAttributes") {
                let md = "[Apple](https://apple.com \"Apple Website\")"
                let renderer = MarkdownRenderer()
                let html = renderer.renderHTML(markdown: md)
                try assertTrue(html.contains("href=\"https://apple.com\""))
                try assertTrue(html.contains("target=\"_blank\""))
                try assertTrue(html.contains("rel=\"noopener noreferrer\""))
                try assertTrue(html.contains("title=\"Apple Website\""))
                try assertTrue(html.contains(">Apple</a>"))
            }
            
            runner.runTest(name: "testImageRenderingBlockedAndAllowed") {
                let md = "![Remote Photo](https://example.com/test.jpg \"My Photo\")"
                
                // Blocked by default
                let blockedRenderer = MarkdownRenderer(settings: LoupeSettings(allowRemoteImages: false))
                let blockedHTML = blockedRenderer.renderHTML(markdown: md)
                try assertTrue(blockedHTML.contains("image-blocked"))
                try assertTrue(blockedHTML.contains("Remote image blocked"))
                
                // Allowed when enabled
                let allowedRenderer = MarkdownRenderer(settings: LoupeSettings(allowRemoteImages: true))
                let allowedHTML = allowedRenderer.renderHTML(markdown: md)
                try assertTrue(allowedHTML.contains("<img src=\"https://example.com/test.jpg\""))
                try assertTrue(allowedHTML.contains("alt=\"Remote Photo\""))
                try assertTrue(allowedHTML.contains("title=\"My Photo\""))
            }
            
            runner.runTest(name: "testOrderedListCustomStartIndex") {
                let md = "3. Third item\n4. Fourth item\n"
                let renderer = MarkdownRenderer()
                let html = renderer.renderHTML(markdown: md)
                try assertTrue(html.contains("<ol start=\"3\">"))
                try assertTrue(html.contains("<li>Third item</li>"))
            }
            
            runner.runTest(name: "testTaskListRendering") {
                let md = """
                - [x] Finished task
                - [ ] Unfinished task
                """
                let renderer = MarkdownRenderer()
                let html = renderer.renderHTML(markdown: md)
                
                try assertTrue(html.contains("class=\"task-list\""))
                try assertTrue(html.contains("type=\"checkbox\" disabled checked"))
                try assertTrue(html.contains("type=\"checkbox\" disabled>"))
            }
            
            runner.runTest(name: "testTableRendering") {
                let md = """
                | Fruit | Color |
                | :--- | :--- |
                | Apple | Red |
                | Banana | Yellow |
                """
                let renderer = MarkdownRenderer()
                let html = renderer.renderHTML(markdown: md)
                
                try assertTrue(html.contains("<table>"))
                try assertTrue(html.contains("<th>Fruit</th>"))
                try assertTrue(html.contains("<td>Red</td>"))
            }
            
            runner.runTest(name: "testBlockquoteRendering") {
                let md = "> This is an Apple-style callout."
                let renderer = MarkdownRenderer()
                let html = renderer.renderHTML(markdown: md)
                
                try assertTrue(html.contains("<blockquote>"))
                try assertTrue(html.contains("This is an Apple-style callout."))
            }
            
            runner.runTest(name: "testCodeBlockWithLanguage") {
                let md = """
                ```swift
                let x = 42
                ```
                """
                let renderer = MarkdownRenderer()
                let html = renderer.renderHTML(markdown: md)
                
                try assertTrue(html.contains("<pre>"))
                try assertTrue(html.contains("class=\"code-header\""))
                try assertTrue(html.contains("Swift"))
                try assertTrue(html.contains("<code class=\"language-swift\">"))
            }
            
            runner.runTest(name: "testSyntaxHighlightingDisabledSetting") {
                let md = "```swift\nfunc test() {}\n```"
                let renderer = MarkdownRenderer(settings: LoupeSettings(enableSyntaxHighlighting: false))
                let html = renderer.renderHTML(markdown: md)
                
                try assertFalse(html.contains("class=\"hl-kw\""))
                try assertTrue(html.contains("func test() {}"))
            }
            
            runner.runTest(name: "testPageTitleExtractionFromHeading") {
                let md = "# Title of My Doc\n\nContent here."
                let renderer = MarkdownRenderer()
                let html = renderer.renderHTML(markdown: md)
                try assertTrue(html.contains("<title>Title of My Doc</title>"))
                
                let explicitTitleHTML = renderer.renderHTML(markdown: md, documentTitle: "Overridden Title")
                try assertTrue(explicitTitleHTML.contains("<title>Overridden Title</title>"))
            }
            
            runner.runTest(name: "testMaliciousScriptTagSanitized") {
                let md = """
                # Hello
                
                <script>alert('pwned')</script>
                
                [Click me](javascript:alert(1))
                """
                let renderer = MarkdownRenderer()
                let html = renderer.renderHTML(markdown: md)
                
                try assertFalse(html.contains("<script>"))
                try assertFalse(html.contains("javascript:alert"))
                try assertTrue(html.contains("href=\"#\""))
            }
            
            runner.runTest(name: "testLargeFileTruncation") {
                var settings = LoupeSettings()
                settings.maxFileSizeBytes = 1000 // artificially low for test
                
                let largeMD = String(repeating: "Line of text\n", count: 200)
                let renderer = MarkdownRenderer(settings: settings)
                let html = renderer.renderHTML(markdown: largeMD)
                
                try assertTrue(html.contains("loupe-warning-banner"))
                try assertTrue(html.contains("Large document truncated"))
            }
        }
    }
}
