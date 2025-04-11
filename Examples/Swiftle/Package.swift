// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Embedded",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(path: "../../"),
        .package(url: "https://github.com/sliemeobn/elementary-css", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "EmbeddedApp",
            dependencies: [
                .product(name: "ElementaryDOM", package: "elementary-dom"),
                .product(name: "ElementaryCSS", package: "elementary-css"),
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
