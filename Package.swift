// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "airdrop-cli",
    targets: [
        .target(
            name: "airdrop",
            dependencies: []),
        .testTarget(
            name: "airdrop-cli-tests",
            dependencies: ["airdrop"]),
    ]
)
