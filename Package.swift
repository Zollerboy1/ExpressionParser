// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "ExpressionParser",
    products: [
        .library(
            name: "ExpressionParser",
            targets: ["ExpressionParser"]),
    ],
    targets: [
        .target(
            name: "ExpressionParser",
            dependencies: [])
    ]
)
