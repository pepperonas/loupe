import Foundation
import LoupeCore

@MainActor
public enum SettingsTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("LoupeSettings") {

            runner.runTest(name: "testDefaults") {
                let s = LoupeSettings()
                try assertEqual(s.appearance, .system)
                try assertEqual(s.textSize, .standard)
                // Vertragswert aus Spec §6.
                try assertEqual(s.expansionLineBudget, 300)
                try assertTrue(s.showTypeBadges)
            }

            runner.runTest(name: "testRoundTripThroughJSON") {
                var s = LoupeSettings()
                s.appearance = .dark
                s.expansionLineBudget = 42
                let data = try JSONEncoder().encode(s)
                let back = try JSONDecoder().decode(LoupeSettings.self, from: data)
                try assertEqual(back, s)
            }

            runner.runTest(name: "testAppGroupConstants") {
                try assertEqual(LoupeSettings.appGroupSuiteName, "group.io.celox.loupe")
                try assertEqual(LoupeSettings.settingsKey, "io.celox.loupe.settings")
            }

            runner.runTest(name: "testTextSizeFontSizes") {
                try assertEqual(LoupeTextSize.small.baseFontSizePx, 12)
                try assertEqual(LoupeTextSize.standard.baseFontSizePx, 13)
                try assertEqual(LoupeTextSize.large.baseFontSizePx, 15)
                try assertEqual(LoupeTextSize.small.markdownBaseFontSizePx, 14)
                try assertEqual(LoupeTextSize.standard.markdownBaseFontSizePx, 16)
                try assertEqual(LoupeTextSize.large.markdownBaseFontSizePx, 18)
            }

            runner.runTest(name: "testBackwardCompatibilityFromV1") {
                let v1JSON = """
                {"appearance":"dark","textSize":"small","expansionLineBudget":120,"showTypeBadges":false}
                """
                let decoded = try JSONDecoder().decode(LoupeSettings.self, from: Data(v1JSON.utf8))
                try assertEqual(decoded.appearance, .dark)
                try assertEqual(decoded.textSize, .small)
                try assertEqual(decoded.expansionLineBudget, 120)
                try assertFalse(decoded.showTypeBadges)
                try assertEqual(decoded.contentWidth, .standard)
                try assertFalse(decoded.allowRemoteImages)
                try assertTrue(decoded.enableSyntaxHighlighting)
            }
        }
    }
}
