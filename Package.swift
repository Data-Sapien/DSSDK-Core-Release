// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "DSSDKCore",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "DSSDKCore", targets: ["DSSDKCore"])
    ],
    dependencies: [
        // “mlx-swift-lib” from Data-Sapien (using the main branch)
        .package(
            url: "https://github.com/Data-Sapien/mlx-swift-lib.git",
            .branch("main")
        ),
        // “mlx-swift” (pin to at least v0.21.2, up to next minor)
        .package(
            url: "https://github.com/ml-explore/mlx-swift.git",
            .upToNextMinor(from: "0.21.2")
        ),
    ],
    targets: [
        // 1) Vendorled Realm frameworks
        .binaryTarget(name: "Realm", path: "./Realm.xcframework"),
        .binaryTarget(name: "RealmSwift", path: "./RealmSwift.xcframework"),

        // 2) Your SDK’s XCFramework
        .binaryTarget(name: "DSSDK", path: "./DSSDK.xcframework"),

        // 3) A tiny wrapper that re-exports DSSDK & Realm
        .target(
            name: "DSSDKCore",
            dependencies: [
                "DSSDK",
                "Realm",
                "RealmSwift",
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXLLM", package: "mlx-swift-lib"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lib"),

            ],
            path: "Sources/DSSDKCore",
            resources: [
                .process("Resources/form-js.css"),
                .process("Resources/form-viewer.umd.js"),
            ]
        ),
    ]
)
