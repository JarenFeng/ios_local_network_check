// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ios_local_network_check",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "ios-local-network-check", targets: ["ios_local_network_check"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ios_local_network_check",
            dependencies: []
        )
    ]
)
