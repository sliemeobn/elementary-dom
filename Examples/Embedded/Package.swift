// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "Embedded",
    dependencies: [
        .package(name: "ElementaryDOM", path: "../../"),
        .package(url: "https://github.com/swifweb/EmbeddedFoundation", branch: "0.1.0"),
        .package(url: "https://github.com/sliemeobn/JavaScriptKit", branch: "swift-embedded"),
    ],
    targets: [
        .executableTarget(
            name: "EmbeddedApp",
            dependencies: [
                .product(name: "ElementaryDOM", package: "ElementaryDOM"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "Foundation", package: "EmbeddedFoundation"),
            ]
        ),
    ]
)
