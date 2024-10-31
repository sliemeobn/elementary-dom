// swift-tools-version:5.10
import PackageDescription

let shouldBuildForEmbedded =
    Context.environment["JAVASCRIPTKIT_EXPERIMENTAL_EMBEDDED_WASM"].flatMap(Bool.init) ?? false

let extraDependencies: [Target.Dependency] = shouldBuildForEmbedded
    ? [.product(name: "dlmalloc", package: "swift-dlmalloc")]
    : []

let package = Package(
    name: "Embedded",
    platforms: [.macOS(.v14)],
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
            swiftSettings: [
                .enableExperimentalFeature("Embedded"),
                .enableExperimentalFeature("Extern"),
                .unsafeFlags([
                    "-Xfrontend", "-gnone",
                    "-Xfrontend", "-disable-stack-protector",
                ]),
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xclang-linker", "-nostdlib",
                    "-Xlinker", "--no-entry",
                    "-Xlinker", "--export-if-defined=__main_argc_argv",
                ]),
            ]
        ),
    ]
)
