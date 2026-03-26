// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Timbre",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0")
    ],
    targets: [
        .executableTarget(
            name: "Timbre",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit"),
                .product(name: "SpeakerKit", package: "WhisperKit"),
            ],
            path: "Sources/Timbre",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "TimbreTests",
            dependencies: ["Timbre"],
            path: "Tests/TimbreTests"
        )
    ]
)
