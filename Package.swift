
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
        .package(url: "https://github.com/swiftwasm/carton", from: "1.0.0"),
        .package(url: "https://github.com/sliemeobn/JavaScriptKit", branch: "swift-embedded"),
        .package(url: "https://github.com/sliemeobn/elementary", branch: "experiment/elementary-dom"),
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
        // .executableTarget(
        //     name: "ExampleApp",
        //     dependencies: [
        //         .target(name: "ElementaryDOM"),
        //         .product(name: "String16", package: "String16"),
        //         .product(name: "JavaScriptKitEmbedded", package: "JavaScriptKit"),
        //     ]
        // ),
        // .executableTarget(
        //     name: "TestApp",
        //     dependencies: [
        //         .product(name: "JavaScriptKit", package: "JavaScriptKit"),
        //     ]
        // ),
    ]
)
