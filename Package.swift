// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PopDeck",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PopDeck", targets: ["PopDeck"])
    ],
    targets: [
        .executableTarget(
            name: "PopDeck",
            path: "Sources/HaloHub",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
