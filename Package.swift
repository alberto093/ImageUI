// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ImageUI",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "ImageUI", targets: ["ImageUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Nuke", exact: "12.4.0"),
    ],
    targets: [
        .target(
            name: "ImageUI",
            dependencies: [
                "Nuke",
                .product(name: "NukeExtensions", package: "Nuke"),
                .product(name: "NukeUI", package: "Nuke"),
                .product(name: "NukeVideo", package: "Nuke")],
            path: "",
            exclude: ["Demo"],
            sources: ["Sources"],
            resources: [.process("Resources"), .process("README.md")]
        )
    ]
)
