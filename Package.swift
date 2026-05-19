// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "XCopy",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "XCopy", targets: ["XCopy"])
    ],
    targets: [
        .executableTarget(
            name: "XCopy",
            path: "Sources/XCopy"
        )
    ]
)
