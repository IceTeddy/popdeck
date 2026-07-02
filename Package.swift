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
            dependencies: [
                .target(name: "Sparkle")
            ],
            path: "Sources/HaloHub",
            resources: [
                .process("Resources")
            ]
        ),
        .binaryTarget(
            name: "Sparkle",
            url: "https://github.com/sparkle-project/Sparkle/releases/download/2.9.3/Sparkle-for-Swift-Package-Manager.zip",
            checksum: "3a5d7fd698acc39c122e75764ed3614b472b284cc483f32ae7006d86c513370c"
        )
    ]
)
