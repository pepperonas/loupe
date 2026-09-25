import Foundation
import LoupeCore

@MainActor
public enum ExtensionStatusTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("ExtensionStatus") {

            runner.runTest(name: "testTitles") {
                try assertEqual(ExtensionStatus.active.title, "Installiert und aktiv")
                try assertEqual(ExtensionStatus.installed.title, "Installiert, aber deaktiviert")
                try assertEqual(ExtensionStatus.notInstalled.title, "Nicht registriert")
            }

            runner.runTest(name: "testIsOperational") {
                try assertTrue(ExtensionStatus.active.isOperational)
                try assertTrue(ExtensionStatus.installed.isOperational)
                try assertFalse(ExtensionStatus.notInstalled.isOperational)
            }

            runner.runTest(name: "testBundleIdConstant") {
                try assertEqual(ExtensionStatusChecker.extensionBundleId, "io.celox.loupe.preview")
            }

            runner.runTest(name: "testParsesPluginkitOutput") {
                // Reine Auswertung, ohne Prozessaufruf -- damit der Test
                // auf jeder Maschine dasselbe tut.
                try assertEqual(
                    ExtensionStatusChecker.interpret("+    io.celox.loupe.preview(0.1.0)\t…"),
                    .active)
                try assertEqual(
                    ExtensionStatusChecker.interpret("!    io.celox.loupe.preview(0.1.0)\t…"),
                    .installed)
                try assertEqual(ExtensionStatusChecker.interpret(""), .notInstalled)
            }

            runner.runTest(name: "testSandboxRefusalIsUnknownNotMissing") {
                // So antwortet pluginkit, wenn die (sandboxed) App es aufruft --
                // gemessen am 2026-09-26. Das heisst NICHT, dass die Erweiterung fehlt.
                let refused = "match: unauthorized discovery flag (PKDiscoverAll)\n"
                try assertEqual(ExtensionStatusChecker.interpret(refused), .unknown)
                try assertFalse(ExtensionStatus.unknown.title.contains("Nicht registriert"))
                try assertFalse(ExtensionStatus.unknown.isOperational)
            }
        }
    }
}
