// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "DSSDKCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "DSSDKCore", targets: ["DSSDKCore"])
    ],
    dependencies: [
        // Realm yok!
    ],
    targets: [
        .binaryTarget(name: "llama", path: "./llama.xcframework"),
        .binaryTarget(name: "DSSDK", path: "./DSSDK.xcframework"),

        .target(
            name: "DSSDKCore",
            dependencies: [
                "DSSDK",
                "llama"
            ],
            path: "Sources/DSSDKCore",
            resources: [
                .process("Resources/form-js.css"),
                .process("Resources/form-viewer.umd.js"),
            ]
        ),
    ]
)

