// swift-tools-version:6.0
import PackageDescription

let shouldBuildForEmbedded =
    Context.environment["JAVASCRIPTKIT_EXPERIMENTAL_EMBEDDED_WASM"].flatMap(Bool.init) ?? false

let extraDependencies: [Target.Dependency] =
    shouldBuildForEmbedded
    ? [.product(name: "dlmalloc", package: "swift-dlmalloc")]
    : []

let package = Package(
    name: "Embedded",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(name: "ElementaryDOM", path: "../../"),
        .package(url: "https://github.com/swiftwasm/swift-dlmalloc", from: "0.1.0"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "EmbeddedApp",
            dependencies: [
                .product(name: "ElementaryDOM", package: "ElementaryDOM"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ] + extraDependencies,
            cSettings: [.unsafeFlags(["-fdeclspec"])],
            swiftSettings: shouldBuildForEmbedded
                ? [
                    .enableExperimentalFeature("Embedded"),
                    .enableExperimentalFeature("Extern"),
                    .unsafeFlags([
                        "-Xfrontend", "-gnone",
                        "-Xfrontend", "-disable-stack-protector",
                    ]),
                ] : nil,
            linkerSettings: true
                ? [
                    .unsafeFlags([
                        "-Xclang-linker", "-nostdlib",
                        "-Xlinker", "--no-entry",
                        "-Xlinker", "--export-if-defined=__main_argc_argv",
                    ])
                ] : nil
        )
    ],
    swiftLanguageModes: [.v5]
)
