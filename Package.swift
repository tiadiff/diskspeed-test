// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SSDSpeedTest",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SSDSpeedTest", targets: ["SSDSpeedTest"])
    ],
    targets: [
        .executableTarget(
            name: "SSDSpeedTest",
            path: "Sources"
        )
    ]
)
