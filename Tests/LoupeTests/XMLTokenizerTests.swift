import Foundation
import LoupeCore

/// XML (und HTML) -- quote-bewusst: ein ">" im Attributwert, in Kommentaren,
/// in CDATA oder im DOCTYPE darf ein Tag nicht beenden.
@MainActor
public enum XMLTokenizerTests {
    private static func xml(_ code: String) -> String {
        SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: "xml")
    }
    private static func html(_ code: String) -> String {
        SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: "html")
    }

    public static func run() {
        let runner = TestRunner.shared
        runner.suite("XML") {

            runner.runTest(name: "testElementAttributeValueAndPunctuationAreDistinct") {
                let h = xml(#"<server host="api" port='8443'/>"#)
                try assertTrue(h.contains(#"<span class="hl-punct">&lt;</span><span class="hl-tag">server</span>"#), h)
                try assertTrue(h.contains(#"<span class="hl-attr">host</span><span class="hl-op">=</span><span class="hl-str">&quot;api&quot;</span>"#), h)
                try assertTrue(h.contains(#"<span class="hl-str">&#39;8443&#39;</span>"#), h)
                try assertTrue(h.contains(#"<span class="hl-punct">/&gt;</span>"#), h)
            }

            runner.runTest(name: "testClosingTagAndNamespacedNames") {
                let h = xml(#"<ns:item xmlns:ns="urn:x" ns:id="42">x</ns:item>"#)
                try assertTrue(h.contains(#"<span class="hl-tag">ns:item</span>"#), h)
                try assertTrue(h.contains(#"<span class="hl-attr">xmlns:ns</span>"#), h)
                try assertTrue(h.contains(#"<span class="hl-punct">&lt;/</span><span class="hl-tag">ns:item</span><span class="hl-punct">&gt;</span>"#), h)
            }

            runner.runTest(name: "testGreaterThanInsideAttributeValueDoesNotEndTheTag") {
                let h = xml(#"<rule when="load > 0.8" action="scale">text</rule>"#)
                try assertTrue(h.contains(#"<span class="hl-str">&quot;load &gt; 0.8&quot;</span>"#), h)
                try assertTrue(h.contains(#"<span class="hl-attr">action</span>"#), "Attribut NACH dem > wird noch erkannt: \(h)")
            }

            runner.runTest(name: "testCDATAIsTextNotMarkup") {
                let h = xml(#"<s><![CDATA[if (a < b && c > d) x("<not a tag>");]]></s>"#)
                try assertTrue(h.contains(#"<span class="hl-kw">&lt;![CDATA[</span>"#), h)
                try assertTrue(h.contains(#"<span class="hl-kw">]]&gt;</span>"#), h)
                try assertFalse(h.contains(#"<span class="hl-tag">b</span>"#), "a < b ist kein Tag: \(h)")
                try assertFalse(h.contains(#"<span class="hl-tag">not</span>"#), h)
                try assertTrue(h.contains(#"<span class="hl-tag">s</span><span class="hl-punct">&gt;</span>"#), "das schliessende </s> wird wieder erkannt")
            }

            runner.runTest(name: "testCommentsSpanLinesAndMayContainGreaterThan") {
                let h = xml("<!-- a > b\n still comment --><x/>")
                try assertTrue(h.contains(#"<span class="hl-com">&lt;!-- a &gt; b</span>"#), h)
                try assertTrue(h.contains(#"<span class="hl-com"> still comment --&gt;</span>"#), h)
                try assertTrue(h.contains(#"<span class="hl-tag">x</span>"#), h)
            }

            runner.runTest(name: "testProcessingInstruction") {
                let h = xml(#"<?xml version="1.0" encoding="UTF-8"?><r/>"#)
                try assertTrue(h.contains(#"<span class="hl-punct">&lt;?</span><span class="hl-kw">xml</span>"#), h)
                try assertTrue(h.contains(#"<span class="hl-attr">encoding</span>"#), h)
                try assertTrue(h.contains(#"<span class="hl-punct">?&gt;</span>"#), h)
                try assertTrue(h.contains(#"<span class="hl-tag">r</span>"#), h)
            }

            runner.runTest(name: "testDoctypeWithInternalSubsetEndsAtTheRightBracket") {
                let h = xml(#"<!DOCTYPE r [<!ENTITY a "x > y">]><r/>"#)
                try assertTrue(h.contains(#"<span class="hl-kw">&lt;!DOCTYPE</span>"#), h)
                try assertTrue(h.contains(#"<span class="hl-tag">r</span><span class="hl-punct">/&gt;</span>"#), "nach dem DOCTYPE geht normales Markup weiter: \(h)")
            }

            runner.runTest(name: "testEntitiesAreHighlightedButBareAmpersandIsNot") {
                let h = xml("<p>a &amp; b &#169; &#x1F600; & c</p>")
                for e in ["&amp;amp;", "&amp;#169;", "&amp;#x1F600;"] {
                    try assertTrue(h.contains("<span class=\"hl-type\">\(e)</span>"), "\(e) in \(h)")
                }
                try assertTrue(h.contains(" &amp; c"), "nacktes & bleibt Text: \(h)")
            }

            runner.runTest(name: "testLessThanInTextIsNotATag") {
                let h = xml("<p>a < b and 3<4</p>")
                try assertFalse(h.contains(#"<span class="hl-tag">b</span>"#), h)
                try assertEqual(visibleText(h), "<p>a < b and 3<4</p>")
            }

            runner.runTest(name: "testUnterminatedInputTerminatesAndKeepsText") {
                for code in [#"<a href="x"#, "<!-- open", "<![CDATA[ open", "<?xml ", "<!DOCTYPE x [", "<a b='c", "<"] {
                    try assertEqual(visibleText(xml(code)), code, code)
                }
            }

            runner.runTest(name: "testHTMLScriptAndStyleAreRawText") {
                let h = html("<script>if (a<b) go()</script><p class=x>hi</p><style>a>b{}</style>")
                try assertFalse(h.contains(#"<span class="hl-tag">b</span>"#), "Skriptinhalt ist kein Markup: \(h)")
                try assertTrue(h.contains(#"<span class="hl-tag">p</span>"#), h)
                try assertTrue(h.contains(#"<span class="hl-attr">class</span>"#), h)
                try assertTrue(h.contains(#"<span class="hl-str">x</span>"#), "unquotierter HTML-Wert: \(h)")
            }

            runner.runTest(name: "testXMLDialectsUseTheXMLHighlighter") {
                let dialects = ["xsd", "xsl", "xslt", "xaml", "csproj", "vbproj", "fsproj", "vcxproj",
                                "props", "targets", "resx", "wsdl", "nuspec"]
                for ext in dialects {
                    try assertEqual(SupportedLanguage.from(identifier: ext), .xml, ext)
                    let url = URL(fileURLWithPath: "/tmp/Project.\(ext)")
                    try assertTrue(RendererRegistry.renderer(for: url) is SourceCodePreviewRenderer, ext)
                }
                // Dieselbe Liste muss als Typ deklariert und bei Quick Look angemeldet sein,
                // sonst bleibt es bei macOS' dynamischem Typ und niemand ruft Loupe.
                let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
                    .deletingLastPathComponent().deletingLastPathComponent()
                let app = try PropertyListSerialization.propertyList(
                    from: Data(contentsOf: root.appendingPathComponent("Sources/Loupe/Resources/Info.plist")),
                    format: nil) as? [String: Any] ?? [:]
                let exported = (app["UTExportedTypeDeclarations"] as? [[String: Any]]) ?? []
                let decl = exported.first { $0["UTTypeIdentifier"] as? String == "io.celox.loupe.xml-document" }
                let tags = (decl?["UTTypeTagSpecification"] as? [String: Any])?["public.filename-extension"] as? [String] ?? []
                try assertEqual(Set(tags), Set(dialects))
                try assertTrue((decl?["UTTypeConformsTo"] as? [String] ?? []).contains("public.xml"))
                let ext = try PropertyListSerialization.propertyList(
                    from: Data(contentsOf: root.appendingPathComponent("Sources/LoupePreview/Resources/Info.plist")),
                    format: nil) as? [String: Any] ?? [:]
                let attrs = ((ext["NSExtension"] as? [String: Any])?["NSExtensionAttributes"] as? [String: Any]) ?? [:]
                try assertTrue(((attrs["QLSupportedContentTypes"] as? [String]) ?? []).contains("io.celox.loupe.xml-document"))
                // Xcode-eigene Typen bleiben unangetastet.
                for foreign in ["storyboard", "xib", "entitlements"] {
                    try assertFalse(tags.contains(foreign), foreign)
                }
            }

            runner.runTest(name: "testRealisticDocumentRoundTrips") {
                let doc = """
                <?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE configuration SYSTEM "config.dtd">
                <configuration xmlns="urn:acme" version="2.4">
                  <rule when="load > 0.8 &amp;&amp; q &lt; 100"/>
                  <script><![CDATA[ if (a < b) {} ]]></script>
                  <!-- done -->
                </configuration>
                """
                try assertEqual(visibleText(xml(doc)), doc)
            }
        }
    }
}
