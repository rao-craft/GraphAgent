// swift-tools-version:6.0
// GraphAgent: a 3D graph of how things connect (hubs and their leaves as spheres joined by thin cylinders, the
// selected node pulsing, a card with its badge and the start of its text) as plain SwiftUI and SceneKit any app can
// use, written into an app from its own types, as a Granite agent package. An app that links it finds the `graph`
// agent through Granite's roster, with nothing listed by hand.

import PackageDescription

let package = Package(
    name: "GraphAgent",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GraphAgent", targets: ["GraphAgent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/riteshpakala/Granite.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "GraphAgent",
            dependencies: [.product(name: "GraniteAgents", package: "Granite")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(
            name: "GraphAgentTests",
            dependencies: ["GraphAgent", .product(name: "GraniteAgents", package: "Granite")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
