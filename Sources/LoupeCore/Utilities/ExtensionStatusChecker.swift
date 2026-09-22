import Foundation

public enum ExtensionStatus: Equatable, Sendable {
    case active, installed, notInstalled

    public var title: String {
        switch self {
        case .active:       return "Installiert und aktiv"
        case .installed:    return "Installiert, aber deaktiviert"
        case .notInstalled: return "Nicht registriert"
        }
    }

    public var isOperational: Bool { self != .notInstalled }
}

public enum ExtensionStatusChecker {
    public static let extensionBundleId = "io.celox.loupe.preview"

    /// Die Auswertung ist von der Prozessausfuehrung getrennt, damit sie
    /// ohne installierte Erweiterung pruefbar ist.
    public static func interpret(_ output: String) -> ExtensionStatus {
        guard output.contains(extensionBundleId) else { return .notInstalled }
        return output.contains("!") ? .installed : .active
    }

    public static func checkStatus() -> ExtensionStatus {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        process.arguments = ["-m", "-v", "-i", extensionBundleId]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return interpret(String(data: data, encoding: .utf8) ?? "")
        } catch {
            return .notInstalled
        }
    }
}
