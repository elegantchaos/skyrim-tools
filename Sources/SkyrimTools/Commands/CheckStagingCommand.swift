// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/04/2026.
//  All code (c) 2026 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

/// Verifies that the staging repository derived from mod metadata exists and is a git repository.
struct CheckStagingCommand: LoggableCommand {

  /// Errors for the staging check.
  enum CheckStagingError: Swift.Error, CustomStringConvertible {
    /// Staging path does not exist or is not a directory.
    case stagingPathMissing(String)

    /// Staging path is not inside a git repository.
    case notGitRepository(String)

    /// User-facing error description.
    var description: String {
      switch self {
      case .stagingPathMissing(let path):
        return "Staging path not found: \(path)"
      case .notGitRepository(let path):
        return "Staging path is not a git repository: \(path)"
      }
    }
  }

  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "check-staging",
      abstract: "Verify that the staging folder exists and is a git repository."
    )
  }

  /// Enable verbose logs.
  @Flag() var verbose: Bool = false

  /// Mod name or path (e.g. "overrides" or "overrides.json").
  @Option(help: "Mod name or path (e.g. \"overrides\" or \"overrides.json\").")
  var mod: String

  /// Run staging check.
  mutating func run() throws {
    print("\nChecking staging repository...")
    let fm = FileManager.default
    let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
    let (settings, configURL) = try SkyrimToolsSettings.load(from: cwd)
    let mod = try ModMetadata.load(from: self.mod, cwd: cwd)
    let paths = try ModMetadata.derivePaths(settings: settings, configURL: configURL, mod: mod)

    var isDirectory: ObjCBool = false
    guard fm.fileExists(atPath: paths.stagingURL.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    else {
      throw CheckStagingError.stagingPathMissing(paths.stagingURL.path)
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["git", "-C", paths.stagingURL.path, "rev-parse", "--is-inside-work-tree"]
    process.standardOutput = Pipe()
    process.standardError = Pipe()
    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
      throw CheckStagingError.notGitRepository(paths.stagingURL.path)
    }

    log("Staging repository is ready at \(paths.stagingURL.path)")
  }
}
