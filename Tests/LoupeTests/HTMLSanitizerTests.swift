import Foundation
import LoupeCore

@MainActor
public enum HTMLSanitizerTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("HTMLSanitizer") {
            runner.runTest(name: "testEscapeHTML") {
                let input = "<div>Hello & \"World\" 'Test'</div>"
                let escaped = HTMLSanitizer.escapeHTML(input)
                try assertEqual(escaped, "&lt;div&gt;Hello &amp; &quot;World&quot; &#39;Test&#39;&lt;/div&gt;")
                
                try assertEqual(HTMLSanitizer.escapeHTML(""), "")
                try assertEqual(HTMLSanitizer.escapeHTML("Clean text 123"), "Clean text 123")
                try assertEqual(HTMLSanitizer.escapeHTML("a & b < c > d \" e ' f"), "a &amp; b &lt; c &gt; d &quot; e &#39; f")
            }
            
            runner.runTest(name: "testSanitizeURLBlocksJavascript") {
                try assertEqual(HTMLSanitizer.sanitizeURL("javascript:alert(1)"), "#")
                try assertEqual(HTMLSanitizer.sanitizeURL("JAVASCRIPT:alert(1)"), "#")
                try assertEqual(HTMLSanitizer.sanitizeURL("javascript:void(0)"), "#")
                try assertEqual(HTMLSanitizer.sanitizeURL("vbscript:msgbox(1)"), "#")
                try assertEqual(HTMLSanitizer.sanitizeURL("data:text/html,<script>alert(1)</script>"), "#")
                try assertEqual(HTMLSanitizer.sanitizeURL("data:text/javascript;alert(1)"), "#")
                try assertEqual(HTMLSanitizer.sanitizeURL("data:application/javascript;alert(1)"), "#")
            }
            
            runner.runTest(name: "testSanitizeURLEntityEncodedBypasses") {
                try assertEqual(HTMLSanitizer.sanitizeURL("&#106;avascript:alert(1)"), "#")
                try assertEqual(HTMLSanitizer.sanitizeURL("&#x6a;avascript:alert(1)"), "#")
            }
            
            runner.runTest(name: "testSanitizeURLAllowsSafeSchemes") {
                try assertEqual(HTMLSanitizer.sanitizeURL("https://apple.com"), "https://apple.com")
                try assertEqual(HTMLSanitizer.sanitizeURL("http://example.com/test?a=1&b=2"), "http://example.com/test?a=1&amp;b=2")
                try assertEqual(HTMLSanitizer.sanitizeURL("mailto:support@celox.io"), "mailto:support@celox.io")
                try assertEqual(HTMLSanitizer.sanitizeURL("#section-title"), "#section-title")
                try assertEqual(HTMLSanitizer.sanitizeURL("./relative/path.md"), "./relative/path.md")
                try assertEqual(HTMLSanitizer.sanitizeURL("../parent/file.md"), "../parent/file.md")
            }
            
            runner.runTest(name: "testSanitizeURLTrimming") {
                try assertEqual(HTMLSanitizer.sanitizeURL("   https://apple.com   "), "https://apple.com")
                try assertEqual(HTMLSanitizer.sanitizeURL("\n\t#anchor\n"), "#anchor")
            }
            
            runner.runTest(name: "testSanitizeRawHTMLStripsScriptTags") {
                let input = "<p>Safe text</p><script>alert('XSS')</script><b>Bold</b>"
                let result = HTMLSanitizer.sanitizeRawHTML(input)
                try assertFalse(result.contains("<script>"))
                try assertFalse(result.contains("alert"))
                try assertTrue(result.contains("<p>Safe text</p>"))
                try assertTrue(result.contains("<b>Bold</b>"))
                
                // Self closing or unclosed script tag
                let unclosed = "Text<script src=\"evil.js\"/>More text"
                let unclosedRes = HTMLSanitizer.sanitizeRawHTML(unclosed)
                try assertFalse(unclosedRes.contains("<script"))
            }
            
            runner.runTest(name: "testSanitizeRawHTMLStripsIframesAndObjects") {
                let input = "<iframe src=\"https://evil.com\"></iframe><object data=\"bad\"></object><embed src=\"bad.swf\">"
                let result = HTMLSanitizer.sanitizeRawHTML(input)
                try assertFalse(result.contains("<iframe"))
                try assertFalse(result.contains("<object"))
                try assertFalse(result.contains("<embed"))
            }
            
            runner.runTest(name: "testSanitizeRawHTMLStripsFormsAndButtons") {
                let input = "<form action=\"/steal\"><input type=\"text\" name=\"pass\"><button>Submit</button></form>"
                let result = HTMLSanitizer.sanitizeRawHTML(input)
                try assertFalse(result.contains("<form"))
                try assertFalse(result.contains("<button"))
            }
            
            runner.runTest(name: "testSanitizeRawHTMLStripsStylesAndMeta") {
                let input = "<style>body { display: none; }</style><link rel=\"stylesheet\" href=\"bad.css\"><meta http-equiv=\"refresh\">"
                let result = HTMLSanitizer.sanitizeRawHTML(input)
                try assertFalse(result.contains("<style>"))
                try assertFalse(result.contains("<link"))
                try assertFalse(result.contains("<meta"))
            }
            
            runner.runTest(name: "testSanitizeRawHTMLStripsEventHandlers") {
                let input = "<img src=\"foo.png\" onerror=\"alert(1)\" onload=\"exploit()\" ONCLICK=\"evil()\">"
                let result = HTMLSanitizer.sanitizeRawHTML(input)
                try assertFalse(result.contains("onerror"))
                try assertFalse(result.contains("onload"))
                try assertFalse(result.contains("ONCLICK"))
                try assertTrue(result.contains("<img src=\"foo.png\""))
            }
            
            runner.runTest(name: "testSanitizeRawHTMLStripsJavascriptInHrefAndSrc") {
                let input = "<a href=\"javascript:alert(1)\">Link</a><iframe src=\"javascript:exploit()\"></iframe>"
                let result = HTMLSanitizer.sanitizeRawHTML(input)
                try assertFalse(result.contains("javascript:alert"))
                try assertTrue(result.contains("href=\"#\""))
            }
        }
    }
}
