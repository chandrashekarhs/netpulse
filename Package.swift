// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NetPulse",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "NetPulse",
            path: "Sources/NetPulse",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Network"),
            ]
        )
    ]
)
