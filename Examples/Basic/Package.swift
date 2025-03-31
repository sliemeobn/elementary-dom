// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Embedded",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(name: "ElementaryDOM", path: "../../"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", from: "0.26.1"),
    ],
    targets: [
        .executableTarget(
            name: "EmbeddedApp",
            dependencies: [
                .product(name: "ElementaryDOM", package: "ElementaryDOM"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
