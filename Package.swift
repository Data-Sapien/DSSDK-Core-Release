// swift-tools-version:6.0
import PackageDescription

let package = Package(
  name: "DSSDKCore",
  platforms: [.iOS(.v13)],
  products: [
    // Clients do `import DSSDK`
    .library(
      name: "DSSDKCore",
      targets: ["DSSDKCore"]
    ),
  ],
  dependencies: [
    // Realm for your framework’s internal use
    .package(url: "https://github.com/realm/realm-swift.git", from: "10.44.0"),
  ],
  targets: [
    // 1) Your prebuilt XCFramework exposes module DSSDK
    .binaryTarget(
      name: "DSSDK",                    // ← must exactly match the module name inside the .xcframework
      path: "./DSSDK.xcframework"
    ),

    // 2) A tiny Swift wrapper that pulls in Realm and bundles your resources
    .target(
      name: "DSSDKCore",                    // ← same name as the product
      dependencies: [
        "DSSDK",                        // ← the binaryTarget
        .product(name: "RealmSwift", package: "realm-swift"),
      ],
      path: "Sources/DSSDKCore",
      resources: [
        .process("Resources/form-js.css"),
        .process("Resources/form-viewer.umd.js"),
      ]
    ),

    .testTarget(
      name: "DSSDKTests",
      dependencies: ["DSSDK"]
    ),
  ]
)
