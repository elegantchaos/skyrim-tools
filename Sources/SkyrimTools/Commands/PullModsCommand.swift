// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/11/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

struct PullModsCommand: LoggableCommand, GameCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "pull-mods",
      abstract: "Scan game folder and make a mod config file for anything that doesn't have one."
    )
  }

  @Flag() var verbose: Bool = false
  @Option(help: "Path to a folder containing mod data files.") var modsPath: String?
  @Option(help: "Path to the game.") var gamePath: String?

  mutating func run() throws {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let modsURL = modsPath.map { URL(fileURLWithPath: $0, relativeTo: cwd) }
    guard let modsURL else {
      print("No mods path specified.")
      return
    }

    let files = try FileManager.default.contentsOfDirectory(
      at: dataURL, includingPropertiesForKeys: [])
    for url in files {
      let ext = url.pathExtension.lowercased()
      if ext == "esp" || ext == "esm" || ext == "esl" {
        try processMod(url: url, modsURL: modsURL)
      }

    }
    log("Processing mods...")
    log("Done.")
  }

  func processMod(url: URL, modsURL: URL) throws {
    let modName = url.lastPathComponent
    let modConfigURL = modsURL.appending(path: modName + ".json")
    if !FileManager.default.fileExists(atPath: modConfigURL.path) {
      log("Creating mod config for \(modName)")
      let blankConfig = "{\n}"
      try blankConfig.write(to: modConfigURL)
    }
  }
}
