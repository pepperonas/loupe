// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Loupe",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LoupeCore", targets: ["LoupeCore"]),
        .executable(name: "Loupe", targets: ["Loupe"]),
        .executable(name: "LoupePreview", targets: ["LoupePreview"]),
        .executable(name: "LoupeTests", targets: ["LoupeTests"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.5.0")
    ],
    targets: [
        .target(
            name: "LoupeCore",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ],
            path: "Sources/LoupeCore"
        ),
        .executableTarget(
            name: "Loupe",
            dependencies: ["LoupeCore"],
            path: "Sources/Loupe",
            exclude: ["Resources"]
        ),
        .executableTarget(
            name: "LoupePreview",
            dependencies: ["LoupeCore"],
            path: "Sources/LoupePreview",
            exclude: ["Resources"],
            linkerSettings: [
                .linkedFramework("QuickLookUI"),
                .linkedFramework("Quartz"),
                .linkedFramework("UniformTypeIdentifiers"),
                .linkedFramework("AppKit"),
                .linkedFramework("WebKit")
            ]
        ),
        .executableTarget(name: "LoupeTests", dependencies: ["LoupeCore"], path: "Tests/LoupeTests")
    ]
)
