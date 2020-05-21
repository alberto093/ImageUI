// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "ImageUI",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(name: "ImageUI", targets: ["ImageUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Nuke.git", from: "9.0.0")
    ],
    targets: [
        .target(name: "ImageUI", dependencies: ["Nuke"])
    ]
)
