// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "verisoul_sdk",
    platforms: [
        .iOS("14.0")
    ],
    products: [
        .library(name: "verisoul-sdk", targets: ["verisoul_sdk"])
    ],
    dependencies: [
        .package(url: "https://github.com/verisoul/ios-sdk.git", exact: "0.4.70"),
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "verisoul_sdk",
            dependencies: [
                .product(name: "VerisoulSDK", package: "ios-sdk"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
