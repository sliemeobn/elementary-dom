// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "Embedded",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(path: "../../"),
        .package(url: "https://github.com/sliemeobn/elementary-css", branch: "main"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.36.0"),
    ],
    targets: [
        .executableTarget(
            name: "Swiftle",
            dependencies: [
                .product(name: "ElementaryDOM", package: "elementary-dom"),
                .product(name: "ElementaryCSS", package: "elementary-css"),
            ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-z", "-Xlinker", "stack-size=1048576"], .when(platforms: [.wasi], configuration: .debug))
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
