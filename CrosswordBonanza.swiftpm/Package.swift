// swift-tools-version: 5.9

// GENERATED FILE -- do not edit.
// Regenerate with: python3 Tools/make_swiftpm.py
//
// This is the Swift Playgrounds build of Crossword Bonanza, for building the
// game on an iPad. The sources here are copies; CrosswordBonanza/ is the
// source of truth and CrosswordBonanza.xcodeproj is the primary project.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "CrosswordBonanza",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "CrosswordBonanza",
            targets: ["AppModule"],
            bundleIdentifier: "com.crosswordbonanza.game",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .sparkle),
            accentColor: .presetColor(.yellow),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
