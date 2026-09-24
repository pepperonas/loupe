// swift-tools-version: 6.0
// Entwickler-Werkzeug: rendert Beispieldateien mit Loupes ECHTEN Renderern zu HTML.
// Eigenes Paket, damit das Hauptpaket (Loupe) davon unberuehrt bleibt.
import PackageDescription

let package = Package(
    name: "ScreenshotGenerator",
    platforms: [.macOS(.v14)],
    dependencies: [.package(name: "Loupe", path: "../..")],
    targets: [
        .executableTarget(
            name: "render-previews",
            dependencies: [.product(name: "LoupeCore", package: "Loupe")]
        )
    ]
)
