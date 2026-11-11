import Foundation
import LoupeCore

@MainActor
public enum CSSGeneratorTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("CSSGenerator") {

            runner.runTest(name: "testSystemAppearanceEmitsBothThemes") {
                var s = LoupeSettings(); s.appearance = .system
                let css = CSSGenerator.generateCSS(settings: s)
                try assertTrue(css.contains("prefers-color-scheme: dark"),
                               "System-Modus braucht die Media-Query")
            }

            runner.runTest(name: "testFixedAppearanceOmitsMediaQuery") {
                // Bei fester Wahl darf die OS-Einstellung NICHT mitreden --
                // sonst kippt ein auf hell gestelltes Fenster nachts um.
                var s = LoupeSettings(); s.appearance = .light
                let css = CSSGenerator.generateCSS(settings: s)
                try assertFalse(css.contains("prefers-color-scheme"))
            }

            runner.runTest(name: "testAllRenderClassesArePresent") {
                let css = CSSGenerator.generateCSS(settings: LoupeSettings())
                for cls in [".lp-tree", ".lp-node", ".lp-key", ".lp-str", ".lp-num",
                            ".lp-bool", ".lp-null", ".lp-count", ".lp-peek",
                            ".lp-omitted", ".lp-banner", ".lp-excerpt", ".lp-caret"] {
                    try assertTrue(css.contains(cls), "fehlt: \(cls)")
                }
            }

            runner.runTest(name: "testTextSizeReachesTheCSS") {
                var s = LoupeSettings(); s.textSize = .large
                try assertTrue(CSSGenerator.generateCSS(settings: s).contains("15px"))
            }

            runner.runTest(name: "testNoJavaScriptAnywhere") {
                // Die Doktrin des Projekts, hier festgenagelt.
                let css = CSSGenerator.generateCSS(settings: LoupeSettings())
                try assertFalse(css.lowercased().contains("<script"))
                try assertFalse(css.lowercased().contains("javascript:"))
            }

            runner.runTest(name: "testTreeIsMonospace") {
                let css = CSSGenerator.generateCSS(settings: LoupeSettings())
                try assertTrue(css.contains("ui-monospace") || css.contains("SFMono"))
            }

            runner.runTest(name: "testCSVSystemAppearanceEmitsBothThemes") {
                var s = LoupeSettings(); s.appearance = .system
                let css = CSSGenerator.generateCSVCSS(settings: s)
                try assertTrue(css.contains("prefers-color-scheme: dark"))
            }

            runner.runTest(name: "testCSVFixedAppearanceDark") {
                var s = LoupeSettings(); s.appearance = .dark
                let css = CSSGenerator.generateCSVCSS(settings: s)
                try assertFalse(css.contains("prefers-color-scheme"))
                try assertTrue(css.contains("--bg: #1e1e1e"))
            }

            runner.runTest(name: "testCSVClassesArePresent") {
                let css = CSSGenerator.generateCSVCSS(settings: LoupeSettings())
                for cls in [".lp-csv-container", ".lp-csv-toolbar", ".lp-csv-badge",
                            ".lp-csv-table-wrapper", ".lp-csv-table", ".lp-csv-row-num",
                            ".lp-csv-num", ".lp-banner", ".lp-csv-empty"] {
                    try assertTrue(css.contains(cls), "fehlt in CSV CSS: \(cls)")
                }
            }

            runner.runTest(name: "testCSVNoJavaScript") {
                let css = CSSGenerator.generateCSVCSS(settings: LoupeSettings())
                try assertFalse(css.lowercased().contains("<script"))
                try assertFalse(css.lowercased().contains("javascript:"))
            }

            runner.runTest(name: "testCodeSystemAppearanceEmitsBothThemes") {
                var s = LoupeSettings(); s.appearance = .system
                let css = CSSGenerator.generateCodeCSS(settings: s)
                try assertTrue(css.contains("prefers-color-scheme: dark"))
            }

            runner.runTest(name: "testCodeFixedAppearanceDark") {
                var s = LoupeSettings(); s.appearance = .dark
                let css = CSSGenerator.generateCodeCSS(settings: s)
                try assertFalse(css.contains("prefers-color-scheme"))
            }

            runner.runTest(name: "testCodeClassesArePresent") {
                let css = CSSGenerator.generateCodeCSS(settings: LoupeSettings())
                for cls in [".lp-code-container", ".lp-toolbar", ".lp-filename", ".lp-badge",
                            ".lp-code-scroll", ".lp-code-table", ".lp-line-no", ".lp-line-code",
                            ".hl-kw", ".hl-type", ".hl-str", ".hl-num", ".hl-com"] {
                    try assertTrue(css.contains(cls), "fehlt in Code CSS: \(cls)")
                }
            }

            // Genau EIN Scrollbereich: Seite und Codekasten scrollten frueher beide,
            // mit dauerhaft sichtbaren Balken standen zwei senkrechte nebeneinander.
            runner.runTest(name: "testCodeViewHasExactlyOneScroller") {
                let css = CSSGenerator.generateCodeCSS(settings: LoupeSettings())
                func rule(_ selector: String) -> String {
                    guard let start = css.range(of: "\n" + selector + " {"),
                          let end = css.range(of: "}", range: start.upperBound..<css.endIndex) else { return "" }
                    return String(css[start.upperBound..<end.lowerBound])
                }
                let body = rule("body"), scroll = rule(".lp-code-scroll"), box = rule(".lp-code-container")
                try assertTrue(body.contains("overflow: hidden"), "die Seite darf nicht selbst scrollen")
                try assertTrue(body.contains("padding: 0;"), "kein Rahmen um die Vorschau")
                try assertTrue(rule("html, body").contains("height: 100%"))
                try assertTrue(box.contains("height: 100%"))
                try assertTrue(scroll.contains("overflow: auto") && scroll.contains("min-height: 0"))
                try assertFalse(scroll.contains("border"), "kein innerer Rahmen um den Code")
            }

            runner.runTest(name: "testCSVWrapperScrollsOnlySideways") {
                let css = CSSGenerator.generateCSVCSS(settings: LoupeSettings())
                let rest = css.components(separatedBy: ".lp-csv-table-wrapper {").dropFirst().first ?? ""
                let rule = rest.components(separatedBy: "}").first ?? ""
                try assertTrue(rule.contains("overflow-y: hidden"))
            }

            runner.runTest(name: "testCodeNoJavaScript") {
                let css = CSSGenerator.generateCodeCSS(settings: LoupeSettings())
                try assertFalse(css.lowercased().contains("<script"))
                try assertFalse(css.lowercased().contains("javascript:"))
            }
        }
    }
}
