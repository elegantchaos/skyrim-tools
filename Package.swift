// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 31/10/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

// swift-tools-version:6.2

import PackageDescription

let package = Package(
  name: "skyrim-tools",

  platforms: [
    .macOS(.v26)
  ],

  products: [
    .executable(
      name: "skyrim-tools",
      targets: ["SkyrimTools"]
    )
  ],

  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    .package(url: "https://github.com/elegantchaos/Matchable.git", from: "1.0.0"),
    .package(url: "https://github.com/elegantchaos/Versionator.git", from: "2.1.0"),
    .package(url: "https://github.com/swiftlang/swift-subprocess.git", from: "0.2.1"),
    .package(url: "https://github.com/elegantchaos/SwiftESP.git", branch: "skyrim-tools"),
  ],

  targets: [
    .target(
      name: "DictionaryMerger"
    ),

    .executableTarget(
      name: "SkyrimTools",
      dependencies: [
        "DictionaryMerger",
        "SwiftESP",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      plugins: [
        .plugin(name: "VersionatorPlugin", package: "Versionator")
      ]
    ),

    .target(
      name: "TestData",
      resources: [
        .process("Resources")
      ]
    ),

    .testTarget(
      name: "SkyrimToolsTests",
      dependencies: [
        "SkyrimTools",
        .product(name: "Matchable", package: "Matchable"),
        "TestData",
      ]
    ),

    .testTarget(
      name: "DictionaryMergerTests",
      dependencies: [
        "DictionaryMerger",
        .product(name: "Matchable", package: "Matchable"),
      ]
    ),

    .testTarget(
      name: "SkyrimToolsIntegrationTests",
      dependencies: [
        "SkyrimTools",
        "TestData",
        .product(name: "Subprocess", package: "swift-subprocess"),
      ]
    ),
  ]
)
