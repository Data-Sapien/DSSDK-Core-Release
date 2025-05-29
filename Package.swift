// swift-tools-version:6.0
import PackageDescription

let package = Package(
  name: "DSSDKCore",
  platforms: [.iOS(.v13)],
  products: [
    .library(name: "DSSDKCore", targets: ["DSSDKCore"])
  ],
  targets: [
    // 1) Vendorled Realm frameworks
    .binaryTarget(name: "Realm",     path: "./Realm.xcframework"),
    .binaryTarget(name: "RealmSwift",path: "./RealmSwift.xcframework"),

    // 2) Your SDK’s XCFramework
    .binaryTarget(name: "DSSDK",     path: "./DSSDK.xcframework"),

    // 3) A tiny wrapper that re-exports DSSDK & Realm
    .target(
      name: "DSSDKCore",
      dependencies: [
        "DSSDK",
        "Realm",
        "RealmSwift"
      ],
      path: "Sources/DSSDKCore",
      resources: [
        .process("Resources/form-js.css"),
        .process("Resources/form-viewer.umd.js")
      ]
    )
  ]
)
