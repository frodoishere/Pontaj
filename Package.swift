// swift-tools-version: 5.9
import PackageDescription

// The accounting model is Foundation-only. This package exercises the same
// sources as the iOS app without requiring SwiftUI, Combine, or an iOS SDK.
let package = Package(
    name: "PontajCore",
    products: [.library(name: "PontajCore", targets: ["PontajCore"])],
    targets: [
        .target(
            name: "PontajCore",
            path: "Pontaj",
            exclude: [
                "Assets.xcassets", "Views", "Utils", "ContentView.swift",
                "PontajApp.swift", "Store/PontajStore.swift", "Models/Project.swift"
            ],
            sources: ["Models/TimeEntry.swift", "Store/Stats.swift"]
        ),
        .testTarget(
            name: "PontajCoreTests",
            dependencies: ["PontajCore"],
            path: "Tests/PontajCoreTests"
        )
    ]
)
