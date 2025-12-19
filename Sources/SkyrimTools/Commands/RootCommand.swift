// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

/// Root command that's run if no subcommand is specified.
///
/// Handles the `--version` flag, or shows the help if no arguments are provided.
@main
struct RootCommand: AsyncParsableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "json-merge",
      abstract: "Assorted tools for merging configuration files.",
      subcommands: [
        AlsarCommand.self,
        MergeCommand.self,
        ModsCommand.self,
        NPCSCommand.self,
        OverlayCommand.self,
        PullModsCommand.self,
        UnderwearCommand.self,
        SleepCommand.self,
        ExtractCommand.self,
      ]
    )
  }

  @Flag(help: "Show the version.") var version = false

  mutating func run() async throws {
    if version {
      let string =
        VersionatorVersion.git.contains("-0-") ? VersionatorVersion.full : VersionatorVersion.git
      print("\(Self.configuration.commandName!) \(string)")
    } else {
      throw CleanExit.helpRequest(self)
    }
  }

  /// Error label - adds some extra newlines to separate the error message from the rest of the output.
  public static var _errorLabel: String { "\n\nError" }

}

protocol LoggableCommand: AsyncParsableCommand {
  var verbose: Bool { get }
}

extension LoggableCommand {
  func log(_ message: String, path: [String] = []) {
    if verbose {
      if path.isEmpty {
        print(message, to: &stderr)
      } else {
        let pathString = path.joined(separator: ".")
        print("\(message) [\(pathString)]", to: &stderr)
      }
    }
  }
}
