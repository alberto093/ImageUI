// swift-tools-version:5.1

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
        .package(url: "https://github.com/kean/Nuke.git", .exact("12.1.6"))
    ],
    targets: [
        .target(
            name: "ImageUI",
            dependencies: ["Nuke", "NukeUI", "NukeExtensions"],
            path: "",
            exclude: ["Demo"],
            sources: ["Sources"]
        )
    ]
)
