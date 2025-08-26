// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "Embedded",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(path: "../../"),
        .package(url: "https://github.com/sliemeobn/elementary-css", branch: "main"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", .upToNextMinor(from: "0.33.1")),
    ],
    targets: [
        .executableTarget(
            name: "Swiftle",
            dependencies: [
                .product(name: "ElementaryDOM", package: "elementary-dom"),
                .product(name: "ElementaryCSS", package: "elementary-css"),
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
