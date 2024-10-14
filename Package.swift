
// swift-tools-version: 5.10
import Foundation
import PackageDescription

let shouldBuildForEmbedded =
    ProcessInfo.processInfo.environment["EXPERIMENTAL_EMBEDDED_WASM"].flatMap(Bool.init) ?? false

let package = Package(
    name: "Test",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ElementaryDOM", targets: ["ElementaryDOM"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sliemeobn/JavaScriptKit", branch: "swift-embedded"),
        .package(url: "https://github.com/sliemeobn/elementary", branch: "main"),
    ],
    targets: [
        .target(
            name: "ElementaryDOM",
            dependencies: [
                .product(name: "Elementary", package: "elementary"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ],
            swiftSettings: shouldBuildForEmbedded
                ? [.unsafeFlags(["-Xfrontend", "-emit-empty-object-file"])]
                : []
        ),
    ]
)
