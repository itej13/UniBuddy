// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "UniBuddy",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "UniBuddy", targets: ["UniBuddy"])
    ],
    dependencies: [
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "9.0.0")
    ],
    targets: [
        .executableTarget(
            name: "UniBuddy",
            dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
            ],
            path: "Sources"
        )
    ]
)
