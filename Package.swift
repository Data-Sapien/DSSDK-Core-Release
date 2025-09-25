// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "DSSDKCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "DSSDKCore", targets: ["DSSDKCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/realm/realm-swift.git", from: "10.51.0")
    ],
    targets: [
        .binaryTarget(name: "llama", path: "./llama.xcframework"),
        .binaryTarget(name: "DSSDK", path: "./DSSDK.xcframework"),

        .target(
            name: "DSSDKCore",
            dependencies: [
                "DSSDK",
                "llama",
                .product(name: "Realm", package: "realm-swift"),
                .product(name: "RealmSwift", package: "realm-swift"),
            ],
            path: "Sources/DSSDKCore",
            resources: [
                .process("Resources/form-js.css"),
                .process("Resources/form-viewer.umd.js"),
            ]
        ),
    ]
)
