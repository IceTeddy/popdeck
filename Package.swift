// swift-tools-version: 6.0
import PackageDescription
import Foundation

// A normal checkout always builds Free. PRO must be explicitly prepared from
// an external private source overlay; it is never fetched from a public URL.
let edition = ProcessInfo.processInfo.environment["POPDECK_EDITION"] ?? "free"
precondition(["free", "pro"].contains(edition), "POPDECK_EDITION must be free or pro")
let sourceRoot = edition == "pro" ? ".build/editions/pro/Sources/HaloHub" : "Sources/HaloHub"
let testRoot = edition == "pro" ? ".build/editions/pro/Tests/PopDeckTests" : "Tests/PopDeckTests"
if edition == "pro" {
    precondition(FileManager.default.fileExists(atPath: ".build/editions/pro/prepared.json"), "Run python3 scripts/prepare-edition.py pro before building PRO")
}
let package = Package(
    name: "PopDeck",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "PopDeck", targets: ["PopDeck"])],
    targets: [
        .executableTarget(name: "PopDeck", dependencies: [.target(name: "Sparkle")], path: sourceRoot, resources: [.process("Resources")]),
        .testTarget(name: "PopDeckTests", dependencies: ["PopDeck"], path: testRoot,
                    resources: edition == "pro" ? [.process("Fixtures")] : []),
        .binaryTarget(name: "Sparkle", url: "https://github.com/sparkle-project/Sparkle/releases/download/2.9.3/Sparkle-for-Swift-Package-Manager.zip",
                      checksum: "3a5d7fd698acc39c122e75764ed3614b472b284cc483f32ae7006d86c513370c")
    ]
)
