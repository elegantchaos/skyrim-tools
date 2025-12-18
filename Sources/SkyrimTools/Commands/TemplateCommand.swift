/*

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/11/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

struct PullModsCommand: LoggableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "pull-mods",
      abstract: "Scan game folder and make a mod config file for anything that doesn't have one."
    )
  }

  @Flag() var verbose: Bool = false
  @Option(help: "Path to a folder containing mod data files.") var modsPath: String?
  @Option(help: "Path to the game data.") var dataPath: String?

  mutating func run() throws {
    log("Processing mods...")
    log("Done.")
  }

}

*/
