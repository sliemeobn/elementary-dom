// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "BasicExample",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(name: "elementary-ui", path: "../../"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.36.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "ElementaryUI", package: "elementary-ui")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
