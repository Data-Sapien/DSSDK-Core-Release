// swift-tools-version:6.0
import PackageDescription

let package = Package(
  name: "DSSDKCore",
  platforms: [.iOS(.v13)],
  products: [
    .library(name: "DSSDKCore", targets: ["DSSDKCore"])
  ],
  targets: [
    // 1) Your prebuilt SDK
    .binaryTarget(
      name: "DSSDK",
      path: "./DSSDK.xcframework"
    ),

    // 3) Your wrapper that links everything together
    .target(
      name: "DSSDKCore",
      dependencies: [
        "DSSDK",
      ],
      path: "Sources/DSSDKCore",
      resources: [
        .process("Resources/form-js.css"),
        .process("Resources/form-viewer.umd.js"),
      ]
    )
  ]
)
