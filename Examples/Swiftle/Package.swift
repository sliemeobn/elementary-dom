// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Embedded",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(name: "ElementaryDOM", path: "../../"),
    ],
    targets: [
        .executableTarget(
            name: "EmbeddedApp",
            dependencies: [
                .product(name: "ElementaryDOM", package: "ElementaryDOM"),
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
