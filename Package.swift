// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let featureFlags: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency=complete"),
    .enableUpcomingFeature("StrictConcurrency=complete"),
    .enableUpcomingFeature("ExistentialAny"),
    // .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ImplicitOpenExistentials"),
    .swiftLanguageMode(.v5),
]

let package = Package(
    name: "Test",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/swiftwasm/carton", from: "1.0.0"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", exact: "0.19.2"),
        .package(url: "https://github.com/sliemeobn/elementary", branch: "experiment/elementary-dom"),
    ],
    targets: [
        .target(name: "ElementaryDOM",
                dependencies: [
                    .product(name: "Elementary", package: "elementary"),
                    .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                ],
                swiftSettings: featureFlags),
        .executableTarget(
            name: "ExampleApp",
            dependencies: [
                .target(name: "ElementaryDOM"),
                // .product(name: "Elementary", package: "elementary"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
            ],
            swiftSettings: featureFlags,
        ),
    ]
)
