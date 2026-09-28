import Foundation
import UniformTypeIdentifiers
import LoupeCore

/// C#, F#, Visual Basic, Lua, Dart, Scala, Groovy, R, Perl, Elixir, Objective-C, Zig --
/// und die Typ-Anmeldung, ohne die Quick Look Loupe fuer diese Dateien gar nicht fragt.
@MainActor
public enum MoreLanguagesTests {
    private static func hl(_ code: String, _ lang: String) -> String {
        SyntaxHighlighter.shared.highlight(code: code, languageIdentifier: lang)
    }
    private static func kw(_ w: String) -> String { "<span class=\"hl-kw\">\(w)</span>" }

    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    private static func plist(_ path: String) throws -> [String: Any] {
        let data = try Data(contentsOf: root.appendingPathComponent(path))
        return try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] ?? [:]
    }

    public static func run() {
        let runner = TestRunner.shared

        runner.suite("More languages") {
            runner.runTest(name: "testExtensionsAndAliasesMapToTheirLanguage") {
                let expected: [(String, SupportedLanguage, String)] = [
                    ("cs", .csharp, "C#"), ("csx", .csharp, "C#"), ("csharp", .csharp, "C#"), ("c#", .csharp, "C#"),
                    ("fs", .fsharp, "F#"), ("fsx", .fsharp, "F#"), ("fsi", .fsharp, "F#"),
                    ("vb", .visualBasic, "Visual Basic"),
                    ("lua", .lua, "Lua"), ("dart", .dart, "Dart"),
                    ("scala", .scala, "Scala"), ("sc", .scala, "Scala"),
                    ("groovy", .groovy, "Groovy"), ("gradle", .groovy, "Groovy"),
                    ("r", .r, "R"), ("R", .r, "R"),
                    ("pl", .perl, "Perl"), ("pm", .perl, "Perl"),
                    ("ex", .elixir, "Elixir"), ("exs", .elixir, "Elixir"),
                    ("m", .objectiveC, "Objective-C"), ("mm", .objectiveC, "Objective-C"), ("objc", .objectiveC, "Objective-C"),
                    ("zig", .zig, "Zig")
                ]
                for (id, lang, name) in expected {
                    try assertEqual(SupportedLanguage.from(identifier: id), lang, id)
                    try assertEqual(lang.displayName, name, id)
                }
            }

            runner.runTest(name: "testEveryNewExtensionIsRoutedToTheCodeRenderer") {
                for e in ["cs", "csx", "fs", "fsx", "fsi", "vb", "lua", "dart", "scala", "sc", "groovy",
                          "gradle", "r", "pl", "pm", "ex", "exs", "m", "mm", "zig"] {
                    try assertTrue(SourceCodePreviewRenderer.supportedExtensions.contains(e), e)
                    let r = RendererRegistry.renderer(for: URL(fileURLWithPath: "/tmp/x.\(e)"))
                    try assertTrue(r is SourceCodePreviewRenderer, ".\(e) -> \(String(describing: r))")
                }
            }

            runner.runTest(name: "testCodeRendererShowsTheLanguageBadge") {
                let html = SourceCodePreviewRenderer().renderBody(
                    code: "var x = 1;", filename: "Program.cs", language: .csharp,
                    settings: LoupeSettings(), wasTruncated: false, totalBytes: 10)
                try assertTrue(html.contains(#"<span class="lp-badge">C#</span>"#), html)
            }

            runner.runTest(name: "testCSharpKeywordsTypesAndComments") {
                let html = hl("public sealed record Person(string Name) { /* x */ }\n// done\nvar p = new Person(\"a\");", "cs")
                for w in ["public", "sealed", "record", "string", "var", "new"] {
                    try assertTrue(html.contains(kw(w)), w)
                }
                try assertTrue(html.contains(#"<span class="hl-type">Person</span>"#), html)
                try assertTrue(html.contains(#"<span class="hl-com">/* x */</span>"#), html)
                try assertTrue(html.contains(#"<span class="hl-com">// done</span>"#), html)
            }

            runner.runTest(name: "testCSharpVerbatimStringEndsAtItsQuote") {
                // Backslash ist in @"..." kein Escape: ohne die Regel lief der String bis zum Zeilenende.
                let html = hl(#"var p = @"C:\temp\"; int n = 1;"#, "cs")
                try assertTrue(html.contains(#"<span class="hl-str">@&quot;C:\temp\&quot;</span>"#), html)
                try assertTrue(html.contains(kw("int")), html)
            }

            runner.runTest(name: "testCSharpVerbatimStringDoublesQuotesAndSpansLines") {
                let html = hl("var s = $@\"say \"\"hi\"\"\nnext {x}\"; return;", "cs")
                try assertTrue(html.contains(#"<span class="hl-str">$@&quot;say &quot;&quot;hi&quot;&quot;</span>"#), html)
                try assertTrue(html.contains(#"<span class="hl-str">next {x}&quot;</span>"#), html)
                try assertTrue(html.contains(kw("return")), html)
            }

            runner.runTest(name: "testVerbatimRuleDoesNotLeakIntoOtherLanguages") {
                // In Swift/Kotlin ist @ ein Attribut, kein String-Praefix.
                let html = hl(#"@objc let s = "a\"b"; let n = 2"#, "swift")
                try assertTrue(html.contains(#"<span class="hl-attr">@objc</span>"#), html)
                try assertTrue(html.contains(#"<span class="hl-str">&quot;a\&quot;b&quot;</span>"#), html)
            }

            runner.runTest(name: "testFSharpBlockComment") {
                let html = hl("(* note *)\nlet rec fib n = match n with | 0 -> 0", "fs")
                try assertTrue(html.contains(#"<span class="hl-com">(* note *)</span>"#), html)
                for w in ["let", "rec", "match", "with"] { try assertTrue(html.contains(kw(w)), w) }
            }

            runner.runTest(name: "testVisualBasicCommentsCaseAndStrings") {
                let html = hl("' greet\nDim path As String = \"C:\\temp\\\" : IF x THEN End If", "vb")
                try assertTrue(html.contains(#"<span class="hl-com">&#39; greet</span>"#), html)
                for w in ["Dim", "As", "String", "IF", "THEN", "End", "If"] {
                    try assertTrue(html.contains(kw(w)), "\(w) (Gross-/Kleinschreibung egal)")
                }
                // Kein Backslash-Escape in VB: der String endet am zweiten Anfuehrungszeichen.
                try assertTrue(html.contains(#"<span class="hl-str">&quot;C:\temp\&quot;</span>"#), html)
            }

            runner.runTest(name: "testLuaLineAndBlockComments") {
                let html = hl("--[[ multi\nline ]]\nlocal x = nil -- tail", "lua")
                try assertTrue(html.contains(#"<span class="hl-com">--[[ multi</span>"#), html)
                try assertTrue(html.contains(#"<span class="hl-com">line ]]</span>"#), html)
                try assertTrue(html.contains(#"<span class="hl-com">-- tail</span>"#), html)
                try assertTrue(html.contains(kw("local")) && html.contains(kw("nil")), html)
            }

            runner.runTest(name: "testHashCommentLanguages") {
                for (lang, code, word) in [("r", "x <- NULL # c", "NULL"),
                                           ("pl", "my $x = 1; # c", "my"),
                                           ("ex", "defmodule A do # c", "defmodule")] {
                    let html = hl(code, lang)
                    try assertTrue(html.contains(#"<span class="hl-com"># c</span>"#), "\(lang): \(html)")
                    try assertTrue(html.contains(kw(word)), "\(lang): \(word)")
                }
            }

            runner.runTest(name: "testCStyleLanguagesKeywords") {
                for (lang, code, words) in [
                    ("dart", "final late int x; // c", ["final", "late"]),
                    ("scala", "case class A(val x: Int) // c", ["case", "class", "val"]),
                    ("gradle", "def v = '1' // c", ["def"]),
                    ("zig", "pub fn main() !void { const x: u8 = 1; } // c", ["pub", "fn", "const", "u8"]),
                    ("m", "@interface Foo : NSObject\n@property (nonatomic) BOOL on; // c", ["nonatomic", "BOOL"])
                ] {
                    let html = hl(code, lang)
                    try assertTrue(html.contains(#"<span class="hl-com">// c</span>"#), "\(lang): \(html)")
                    for w in words { try assertTrue(html.contains(kw(w)), "\(lang): \(w) in \(html)") }
                }
                try assertTrue(hl("@interface Foo", "m").contains(#"<span class="hl-attr">@interface</span>"#))
            }

            runner.runTest(name: "testMarkdownFenceAliasesHighlight") {
                for alias in ["csharp", "c#", "fsharp", "lua", "dart", "scala", "groovy", "perl", "elixir", "objc", "zig"] {
                    try assertTrue(SupportedLanguage.from(identifier: alias) != .unknown, alias)
                }
            }

            // Quick Look fragt eine Erweiterung nur fuer deklarierte Typen. Ohne Deklaration
            // bekommt z. B. .cs auf einem frischen Mac einen dynamischen Typ -- dann erscheint
            // nie Loupe, egal was der Renderer kann. Hier wird geprueft, dass Loupe JEDE
            // Endung, die nicht vom System kommt, selbst deklariert UND anmeldet.
            runner.runTest(name: "testThirdPartyAndDynamicExtensionsAreDeclaredAndRegistered") {
                let app = try plist("Sources/Loupe/Resources/Info.plist")
                var declared: [String: String] = [:]
                for d in ((app["UTImportedTypeDeclarations"] as? [[String: Any]]) ?? [])
                    + ((app["UTExportedTypeDeclarations"] as? [[String: Any]]) ?? []) {
                    let uti = d["UTTypeIdentifier"] as? String ?? ""
                    let tags = (d["UTTypeTagSpecification"] as? [String: Any])?["public.filename-extension"] as? [String] ?? []
                    for t in tags { declared[t] = uti }
                }
                let ext = try plist("Sources/LoupePreview/Resources/Info.plist")
                let attrs = (ext["NSExtension"] as? [String: Any])?["NSExtensionAttributes"] as? [String: Any] ?? [:]
                let registered = Set(attrs["QLSupportedContentTypes"] as? [String] ?? [])

                // Endungen, deren Typ macOS NICHT selbst mitbringt (nur Editoren wie CotEditor).
                let mustDeclare = ["rs", "go", "kt", "kts", "sql", "toml", "ini",
                                   "cs", "csx", "fs", "fsx", "fsi", "vb", "lua", "dart", "scala", "sc",
                                   "groovy", "gradle", "ex", "exs", "zig",
                                   "tsx", "jsx", "cjs", "pyw", "scss", "sass", "less", "dockerfile"]
                for e in mustDeclare {
                    guard let uti = declared[e] else { throw TestFailure(message: ".\(e) nicht deklariert", file: #file, line: #line) }
                    try assertTrue(registered.contains(uti), ".\(e): \(uti) fehlt in QLSupportedContentTypes")
                }
                // .ts bleibt dem Video-Typ von macOS -- sonst wuerden echte Videos zu Text.
                try assertTrue(declared["ts"] == nil, ".ts darf Loupe nicht beanspruchen")
                try assertFalse(registered.contains("public.mpeg-2-transport-stream"))
            }

            runner.runTest(name: "testEveryDeclaredTypeConformsToText") {
                // Sonst wuerde "Vorschau aus" (Rohtext-Rueckfall) fuer diese Typen nichts zeigen.
                let app = try plist("Sources/Loupe/Resources/Info.plist")
                for d in ((app["UTImportedTypeDeclarations"] as? [[String: Any]]) ?? [])
                    + ((app["UTExportedTypeDeclarations"] as? [[String: Any]]) ?? []) {
                    let conf = d["UTTypeConformsTo"] as? [String] ?? []
                    let textual = ["public.plain-text", "public.source-code", "public.script", "public.xml",
                                   "public.css", "public.python-script", "com.netscape.javascript-source"]
                    try assertTrue(!Set(conf).isDisjoint(with: textual), "\(d["UTTypeIdentifier"] ?? "?") -> \(conf)")
                }
            }
        }
    }
}
