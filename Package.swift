// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "DSSDKCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "DSSDKCore", targets: ["DSSDKCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift.git", exact: "0.21.2"),
        .package(url: "https://github.com/Data-Sapien/mlx-swift-lib.git", branch: "main"),
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
