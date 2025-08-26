// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "BasicExample",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(name: "ElementaryDOM", path: "../../"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", .upToNextMinor(from: "0.33.1")),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "ElementaryDOM", package: "ElementaryDOM")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
