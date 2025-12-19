// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 31/10/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

struct OverlayCommand: ParsableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "overlay",
      abstract: "Apply multiple overlays."
    )
  }

  @Flag() var verbose: Bool = false
  @Option(help: "The output file for the merged JSON.") var output: String?
  @Option(help: "The overlays directory to apply.") var overlays: String?

  mutating func run() throws {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let overlaysURL =
      overlays.map { URL(fileURLWithPath: $0, relativeTo: cwd) }
      ?? cwd.appending(path: "Overlays")

    let outputURL =
      output.map { URL(fileURLWithPath: $0, relativeTo: cwd) } ?? cwd.appending(path: "Output")

    try? FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

    let overlays = try FileManager.default.contentsOfDirectory(
      at: overlaysURL, includingPropertiesForKeys: [])
    for overlayURL in overlays {
      try self.overlay(url: overlayURL, to: outputURL)
    }
  }

  func overlay(url: URL, to outputURL: URL) throws {

    let decoder = JSONDecoder()
    let configURL = url.appending(path: "config.json")
    let config = try decoder.decode(OverlayConfig.self, from: Data(contentsOf: configURL))
    let name = url.lastPathComponent

    for stage in config.stages {
      if let copyConfig = stage.copy {
        try copy(copyConfig, at: url, to: outputURL, overlay: name)
      }

      if let moveConfig = stage.move {
        try move(moveConfig, at: url, to: outputURL, overlay: name)
      }

      if let mergeConfig = stage.merge {
        try merge(mergeConfig, at: url, to: outputURL, overlay: name)
      }
    }
  }

  func contentsExcludingConfig(at url: URL) -> [String] {
    guard
      let all = try? FileManager.default.contentsOfDirectory(
        at: url, includingPropertiesForKeys: [])
    else {
      return []
    }

    return
      all
      .filter { $0.lastPathComponent != "config.json" }
      .map { $0.lastPathComponent }
  }

  func move(_ config: MoveConfig, at inputRoot: URL, to outputRoot: URL, overlay: String) throws {
    let from = config.from ?? contentsExcludingConfig(at: inputRoot)
    for input in from {
      let inputURL = inputRoot.appending(path: input)
      let outputURL = outputRoot.appending(path: config.to).appending(
        path: inputURL.lastPathComponent)

      do {
        try inputURL.copy(to: outputURL)
        print(
          "\(overlay): moved \(inputURL.lastPathComponent) to \(outputURL.deletingLastPathComponent().lastPathComponent)/"
        )
      } catch {
        print("\(overlay): failed to move \(inputURL.lastPathComponent)")
      }
    }
  }

  func copy(_ config: CopyConfig, at root: URL, to outputURL: URL, overlay: String) throws {
    let inputURL = root.appending(path: config.from)
    let destination = outputURL.appending(path: config.to)
    do {
      try inputURL.copy(to: destination)
      print("\(overlay): copied \(inputURL.lastPathComponent) to \(destination.lastPathComponent)")
    } catch {
      print("\(overlay): failed to copy \(inputURL.lastPathComponent)")
    }
  }

  func merge(_ config: GroupConfig, at root: URL, to outputURL: URL, overlay: String) throws {
    let inputs = config.from.compactMap {
      try? JSONFile(contentsOf: root.appending(path: "\($0).json"))
    }
    let merger = JSONMerger(options: .init(uniqueLists: true, verbose: verbose))
    let merged = try merger.merge(inputs)
    let mergedURL = outputURL.appending(path: config.to)
    try merged.formatted.write(to: mergedURL)
    print("\(overlay): merged \(config.from.count) files to \(mergedURL.lastPathComponent)")
  }
}

struct GroupConfig: Codable {
  let from: [String]
  let to: String
}

struct MoveConfig: Codable {
  let from: [String]?
  let to: String
}

struct OverlayConfig: Codable {
  let stages: [OverlayStage]
}

struct CopyConfig: Codable {
  let from: String
  let to: String
}

struct OverlayStage: Codable {
  let copy: CopyConfig?
  let move: MoveConfig?
  let merge: GroupConfig?
}
