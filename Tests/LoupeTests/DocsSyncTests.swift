import Foundation
import UniformTypeIdentifiers
import LoupeCore

/// Haelt README.md/README.de.md mit dem Code synchron: Versionen, Testzahl,
/// Bildpfade und -- vor allem -- welche Dateitypen Quick Look Loupe wirklich
/// uebergibt. Eine README, die Formate verspricht, die der Finder nie an die
/// Erweiterung schickt, ist schlimmer als keine.
///
/// MUSS als letzte Suite laufen: der Badge-Test vergleicht mit der Gesamtzahl.
@MainActor
public enum DocsSyncTests {
    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    private static func text(_ path: String) throws -> String {
        try String(contentsOf: root.appendingPathComponent(path), encoding: .utf8)
    }

    private static func plist(_ path: String) throws -> [String: Any] {
        let data = try Data(contentsOf: root.appendingPathComponent(path))
        return (try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]) ?? [:]
    }

    private static func matches(_ pattern: String, in s: String, group: Int = 1) -> [String] {
        let re = try! NSRegularExpression(pattern: pattern)
        let ns = s as NSString
        return re.matches(in: s, range: NSRange(location: 0, length: ns.length)).map {
            ns.substring(with: $0.range(at: group))
        }
    }

    /// Backtick-Endungen (`.ps1`) zwischen <!-- name:start --> und <!-- name:end -->.
    private static func markedExtensions(_ name: String, in readme: String) throws -> Set<String> {
        guard let a = readme.range(of: "<!-- \(name):start -->"),
              let b = readme.range(of: "<!-- \(name):end -->"), a.upperBound < b.lowerBound else {
            throw TestFailure(message: "Markierung \(name) fehlt", file: #file, line: #line)
        }
        return Set(matches(#"`\.([A-Za-z0-9+]+)`"#, in: String(readme[a.upperBound..<b.lowerBound])).map { $0.lowercased() })
    }

    private static let readmes = ["README.md", "README.de.md"]

    public static func run() {
        let runner = TestRunner.shared
        runner.suite("Docs sync") {

            runner.runTest(name: "testVersionsAgreeAcrossPlistsAndChangelog") {
                let app = try plist("Sources/Loupe/Resources/Info.plist")["CFBundleShortVersionString"] as? String
                let ext = try plist("Sources/LoupePreview/Resources/Info.plist")["CFBundleShortVersionString"] as? String
                try assertEqual(app, ext, "App und Erweiterung muessen dieselbe Version tragen")
                let released = matches(#"(?m)^## \[(\d+\.\d+\.\d+)\]"#, in: try text("CHANGELOG.md")).first
                try assertEqual(released, app, "neueste Version im CHANGELOG == Info.plist")
            }

            runner.runTest(name: "testEveryLocalImageAndLinkExists") {
                for name in readmes {
                    let md = try text(name)
                    let paths = matches(##"(?:src|srcset)="((?:docs|Tests|Tools|Scripts|Sources)/[^"#]+)""##, in: md)
                        + matches(#"\]\(((?:docs|Tests|Tools|Scripts|Sources|\.github)/[^)#\s]+)\)"#, in: md)
                        + matches(#"\]\(((?:LICENSE|CHANGELOG\.md|README(?:\.de)?\.md))\)"#, in: md)
                    try assertTrue(paths.count > 10, "\(name): zu wenige lokale Verweise gefunden -- Muster kaputt?")
                    for p in Set(paths) {
                        try assertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(p).path),
                                       "\(name) verweist auf fehlende Datei \(p)")
                    }
                }
            }

            runner.runTest(name: "testEnglishAndGermanReadmeStayInStep") {
                let en = try text("README.md"), de = try text("README.de.md")
                let img = #"(?:src|srcset)="(docs/[^"]+)""#
                try assertEqual(Set(matches(img, in: en)), Set(matches(img, in: de)), "dieselben Bilder")
                try assertEqual(matches("img\\.shields\\.io", in: en, group: 0).count,
                                matches("img\\.shields\\.io", in: de, group: 0).count, "gleich viele Badges")
                try assertEqual(try markedExtensions("filetypes", in: en), try markedExtensions("filetypes", in: de))
                try assertEqual(try markedExtensions("unreachable", in: en), try markedExtensions("unreachable", in: de))
            }

            runner.runTest(name: "testEveryRendererExtensionIsDocumentedExactlyOnce") {
                let known = SourceCodePreviewRenderer.supportedExtensions
                    .filter { !["make", "makefile", "docker"].contains($0) }   // Dateinamen, keine Endungen
                    .union(["json", "md", "markdown", "tsv", "log"])
                for name in readmes {
                    let md = try text(name)
                    let listed = try markedExtensions("filetypes", in: md)
                    let unreachable = try markedExtensions("unreachable", in: md)
                    try assertTrue(listed.isDisjoint(with: unreachable),
                                   "\(name): \(listed.intersection(unreachable)) in beiden Listen")
                    let missing = known.subtracting(listed).subtracting(unreachable)
                    try assertTrue(missing.isEmpty, "\(name): undokumentierte Endungen \(missing.sorted())")
                }
            }

            runner.runTest(name: "testDocumentedFinderSupportMatchesQuickLookRegistration") {
                // Welcher Typ kommt bei Quick Look an? Eigene Importe zuerst, sonst das System.
                let app = try plist("Sources/Loupe/Resources/Info.plist")
                var imported: [String: String] = [:]
                let declared = ((app["UTImportedTypeDeclarations"] as? [[String: Any]]) ?? [])
                    + ((app["UTExportedTypeDeclarations"] as? [[String: Any]]) ?? [])
                for decl in declared {
                    let uti = decl["UTTypeIdentifier"] as? String ?? ""
                    let tags = (decl["UTTypeTagSpecification"] as? [String: Any])?["public.filename-extension"] as? [String] ?? []
                    for t in tags { imported[t.lowercased()] = uti }
                }
                let ext = try plist("Sources/LoupePreview/Resources/Info.plist")
                let attrs = ((ext["NSExtension"] as? [String: Any])?["NSExtensionAttributes"] as? [String: Any]) ?? [:]
                let supportedIDs = Set((attrs["QLSupportedContentTypes"] as? [String]) ?? [])
                let supported = supportedIDs.compactMap { UTType($0) }

                func reachable(_ e: String) -> Bool? {
                    if let uti = imported[e] { return supportedIDs.contains(uti) }
                    guard let t = UTType(filenameExtension: e), !t.isDynamic else { return nil }  // auf diesem OS unbestimmt
                    return supported.contains { t == $0 || t.conforms(to: $0) }
                }

                let md = try text("README.md")
                for e in try markedExtensions("filetypes", in: md) where e != "csv" {
                    try assertTrue(reachable(e) != false,
                                   "README verspricht .\(e) im Finder, aber QLSupportedContentTypes deckt den Typ nicht ab")
                }
                // Ob eine "unerreichbare" Endung doch ankommt, haengt von den installierten
                // Programmen ab (auf CI-Runnern mit Xcode bekommt .tsx einen Quellcode-Typ).
                // Stabil pruefbar ist nur: LOUPE SELBST beansprucht sie nicht.
                for e in try markedExtensions("unreachable", in: md) {
                    try assertTrue(imported[e] == nil,
                                   ".\(e) steht als 'nicht im Finder', Loupe deklariert aber selbst einen Typ dafuer")
                    if let t = UTType(filenameExtension: e), !t.isDynamic {
                        try assertFalse(supportedIDs.contains(t.identifier),
                                        ".\(e) steht als 'nicht im Finder', ihr Typ \(t.identifier) ist aber angemeldet")
                    }
                }
            }

            // Als LETZTER Test: totalTests zaehlt ihn bereits mit.
            runner.runTest(name: "testTestBadgeMatchesTheSuite") {
                let total = TestRunner.shared.totalTests
                for name in readmes {
                    let badge = matches(#"badge/Tests-(\d+)%20"#, in: try text(name)).first
                    try assertEqual(badge, String(total), "\(name): Test-Badge (Scripts/update_readme_stats.sh ausfuehren)")
                }
            }
        }
    }
}
