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
        }
    }
}
