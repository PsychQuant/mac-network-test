// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacNetworkTest",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "mac-network-test", targets: ["MacNetworkTestCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .target(name: "NetworkDiagnosis"),
        .executableTarget(
            name: "MacNetworkTestCLI",
            dependencies: [
                "NetworkDiagnosis",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "NetworkDiagnosisTests",
            dependencies: ["NetworkDiagnosis"]
        ),
    ]
)
