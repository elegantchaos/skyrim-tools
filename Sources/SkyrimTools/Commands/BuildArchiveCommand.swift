// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/04/2026.
//  All code (c) 2026 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

/// Builds a `.7z` archive from the configured staging folder.
///
/// This command uses paths derived from mod metadata + settings and keeps
/// the same 7z flags as the current update script for parity.
struct BuildArchiveCommand: LoggableCommand {

  /// Domain errors for archive build workflow.
  enum BuildArchiveError: Swift.Error, CustomStringConvertible {
    /// Configured staging path does not exist.
    case stagingPathMissing(String)

    /// Configured staging path is not a directory.
    case stagingPathIsNotDirectory(String)

    /// 7z tool invocation failed.
    case sevenZipFailed(Int32)

    /// User-facing error description.
    var description: String {
      switch self {
      case .stagingPathMissing(let path):
        return "Configured staging path does not exist: \(path)"
      case .stagingPathIsNotDirectory(let path):
        return "Configured staging path is not a directory: \(path)"
      case .sevenZipFailed(let code):
        return "7z exited with status code \(code)."
      }
    }
  }

  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "build-archive",
      abstract: "Build a 7z archive from the configured staging folder."
    )
  }

  /// Enable verbose logs.
  @Flag() var verbose: Bool = false

  /// Path to mod JSON that defines content and archive names.
  @Option(help: "Path to mod JSON (e.g. overrides.json).")
  var modPath: String

  /// Run archive build.
  mutating func run() async throws {
    let fm = FileManager.default
    let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
    let (settings, configURL) = try SkyrimToolsSettings.load(from: cwd)
    let mod = try ModMetadata.load(from: modPath, cwd: cwd)
    let paths = try ModMetadata.derivePaths(settings: settings, configURL: configURL, mod: mod)
    try execute(paths: paths, emitSummary: true)
  }

  /// Build the archive, optionally printing a summary line.
  mutating func execute(paths: ModMetadata.DerivedPaths, emitSummary: Bool) throws {
    let fm = FileManager.default
    let stagingURL = paths.stagingURL
    let outputArchiveURL = paths.archiveURL

    var isDirectory: ObjCBool = false
    guard fm.fileExists(atPath: stagingURL.path, isDirectory: &isDirectory) else {
      throw BuildArchiveError.stagingPathMissing(stagingURL.path)
    }

    guard isDirectory.boolValue else {
      throw BuildArchiveError.stagingPathIsNotDirectory(stagingURL.path)
    }

    if fm.fileExists(atPath: outputArchiveURL.path) {
      log("Removing existing archive at \(outputArchiveURL.path)")
      try fm.removeItem(at: outputArchiveURL)
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [
      "7z", "a", "-t7z", "-mx=1", "-m0=lzma2", "-ms=on", "-mf=off",
      outputArchiveURL.path,
      "\(stagingURL.path)/*",
    ]

    if !verbose {
      process.standardOutput = Pipe()
      process.standardError = Pipe()
    }

    log("Building archive from \(stagingURL.path)")
    log("Writing archive to \(outputArchiveURL.path)")

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
      throw BuildArchiveError.sevenZipFailed(process.terminationStatus)
    }

    if emitSummary {
      print("Archive created at: \(outputArchiveURL.path)")
    }
  }
}
