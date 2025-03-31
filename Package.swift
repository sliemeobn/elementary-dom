// swift-tools-version: 6.0
import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Test",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ElementaryDOM", targets: ["ElementaryDOM", "Reactivity"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", .upToNextMinor(from: "0.26.1")),
        .package(url: "https://github.com/sliemeobn/elementary", from: "0.5.0"),
        .package(
            url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"601.0.0-prerelease"),
    ],
    targets: [
        .target(
            name: "ElementaryDOM",
            dependencies: [
                .product(name: "Elementary", package: "elementary"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .target(name: "ElementaryDOMMacros"),
                .target(name: "Reactivity"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .macro(
            name: "ElementaryDOMMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]),
        .testTarget(
            name: "ElementaryDOMTests",
            dependencies: ["ElementaryDOM"]
        ),
        /// --- REACTIVITY ---
        .target(
            name: "Reactivity",
            dependencies: ["ReactivityMacros"]
        ),
        .macro(
            name: "ReactivityMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "ReactivityTests",
            dependencies: ["Reactivity"]
        ),
    ]
)
