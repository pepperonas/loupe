import Foundation
import LoupeCore

/// Einstellungen muessen die ERWEITERUNG erreichen. Bis 0.4.0 taten sie das nie:
/// ohne passendes Entitlement landete die Suite im Sandbox-Container der App.
@MainActor
public enum SharedSettingsTests {
    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    private static func entitlements(_ path: String) throws -> [String: Any] {
        let data = try Data(contentsOf: root.appendingPathComponent(path))
        return try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] ?? [:]
    }

    private static func scratch() -> UserDefaults {
        let name = "io.celox.loupe.tests.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    public static func run() {
        let runner = TestRunner.shared
        runner.suite("SharedSettings") {

            runner.runTest(name: "testAppMayWriteTheSharedDomain") {
                let e = try entitlements("Sources/Loupe/Resources/Loupe.entitlements")
                let rw = e["com.apple.security.temporary-exception.shared-preference.read-write"] as? [String] ?? []
                try assertTrue(rw.contains(LoupeSettings.sharedDomain), "App braucht read-write auf \(LoupeSettings.sharedDomain)")
            }

            runner.runTest(name: "testExtensionMayReadTheSharedDomain") {
                let e = try entitlements("Sources/LoupePreview/Resources/LoupePreview.entitlements")
                let ro = e["com.apple.security.temporary-exception.shared-preference.read-only"] as? [String] ?? []
                let rw = e["com.apple.security.temporary-exception.shared-preference.read-write"] as? [String] ?? []
                try assertTrue(ro.contains(LoupeSettings.sharedDomain), "Erweiterung braucht read-only auf \(LoupeSettings.sharedDomain)")
                try assertFalse(rw.contains(LoupeSettings.sharedDomain), "Erweiterung soll nur lesen")
            }

            runner.runTest(name: "testSaveAndLoadGoThroughTheGivenDefaults") {
                let d = scratch()
                var s = LoupeSettings()
                s.previewsEnabled = false
                s.setEnabled(false, for: .markdown)
                s.save(to: d)
                try assertEqual(LoupeSettings.load(from: d), s)
            }

            runner.runTest(name: "testMigrationCopiesLegacyIntoEmptySharedDomain") {
                let legacy = scratch(), shared = scratch()
                var old = LoupeSettings(); old.appearance = .dark; old.textSize = .large
                old.save(to: legacy)
                try assertTrue(LoupeSettings.migrateLegacy(from: legacy, to: shared))
                try assertEqual(LoupeSettings.load(from: shared), old)
            }

            runner.runTest(name: "testMigrationNeverOverwritesSharedSettings") {
                let legacy = scratch(), shared = scratch()
                var old = LoupeSettings(); old.appearance = .dark; old.save(to: legacy)
                var current = LoupeSettings(); current.appearance = .light; current.save(to: shared)
                try assertFalse(LoupeSettings.migrateLegacy(from: legacy, to: shared))
                try assertEqual(LoupeSettings.load(from: shared).appearance, .light)
            }

            runner.runTest(name: "testMigrationIgnoresMissingOrBrokenLegacy") {
                let shared = scratch()
                try assertFalse(LoupeSettings.migrateLegacy(from: nil, to: shared))
                let legacy = scratch()
                legacy.set(Data("kein json".utf8), forKey: LoupeSettings.settingsKey)
                try assertFalse(LoupeSettings.migrateLegacy(from: legacy, to: shared))
                try assertTrue(shared.data(forKey: LoupeSettings.settingsKey) == nil)
            }
        }
    }
}
