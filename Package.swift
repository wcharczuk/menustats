// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MenuStats",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MenuStats", targets: ["MenuStats"])
    ],
    targets: [
        .executableTarget(
            name: "MenuStats",
            resources: [
                .process("Resources/Assets.xcassets")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
