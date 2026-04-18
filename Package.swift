// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NetPulse",
    platforms: [.macOS(.v12)],
    targets: [
        // Thin executable — only wires NSApplication
        .executableTarget(
            name: "NetPulse",
            dependencies: ["NetPulseCore"],
            path: "Sources/NetPulse"
        ),
        // All app logic — imported by the executable and the test target
        .target(
            name: "NetPulseCore",
            path: "Sources/NetPulseCore",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Network"),
                .linkedFramework("UserNotifications"),
            ]
        ),
        .testTarget(
            name: "NetPulseTests",
            dependencies: ["NetPulseCore"],
            path: "Tests/NetPulseTests"
        )
    ]
)
