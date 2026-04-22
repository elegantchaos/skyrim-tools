// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/04/2026.
//  All code (c) 2026 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

/// Deploys a built archive and sidecar manifest to Vortex AutoInstall.
///
/// Reads mod metadata + settings to derive archive and manifest paths,
/// then copies both to AutoInstall and touches a `.rescan` marker.
struct DeployCommand: LoggableCommand {

  /// Domain errors for archive deployment.
  enum DeployError: Swift.Error, CustomStringConvertible {
    /// Required key is missing from config.
    case missingPath(String)

    /// Archive file does not exist.
    case archiveNotFound(String)

    /// Manifest file does not exist.
    case manifestNotFound(String)

    /// User-facing error description.
    var description: String {
      switch self {
      case .missingPath(let key):
        return "Missing required path in skyrim-tools.json: paths.\(key)"
      case .archiveNotFound(let path):
        return "Archive file not found: \(path)"
      case .manifestNotFound(let path):
        return "Manifest file not found: \(path)"
      }
    }
  }

  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "deploy",
      abstract: "Deploy the built archive and manifest to Vortex AutoInstall."
    )
  }

  /// Enable verbose logs.
  @Flag() var verbose: Bool = false

  /// Path to mod JSON that defines content and archive names.
  @Option(help: "Path to mod JSON (e.g. overrides.json).")
  var modPath: String

  /// Run the deployment.
  mutating func run() async throws {
    let fm = FileManager.default
    let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
    let (settings, configURL) = try SkyrimToolsSettings.load(from: cwd)
    let mod = try ModMetadata.load(from: modPath, cwd: cwd)
    let paths = try ModMetadata.derivePaths(
      settings: settings, configURL: configURL, mod: mod)

    let archiveURL = paths.archiveURL
    let manifestURL = paths.manifestURL

    let vortexPaths = settings.paths.vortex
    guard let autoinstallPath = vortexPaths?.autoinstall else {
      throw DeployError.missingPath("vortex.autoinstall")
    }

    let autoinstallURL = SkyrimToolsSettings.resolve(autoinstallPath, relativeTo: configURL)

    guard fm.fileExists(atPath: archiveURL.path) else {
      throw DeployError.archiveNotFound(archiveURL.path)
    }

    guard fm.fileExists(atPath: manifestURL.path) else {
      throw DeployError.manifestNotFound(manifestURL.path)
    }

    try fm.createDirectory(at: autoinstallURL, withIntermediateDirectories: true)

    let destArchiveURL = autoinstallURL.appending(path: archiveURL.lastPathComponent)
    let destManifestURL = autoinstallURL.appending(path: manifestURL.lastPathComponent)

    log("Copying archive to \(destArchiveURL.path)")
    if fm.fileExists(atPath: destArchiveURL.path) {
      try fm.removeItem(at: destArchiveURL)
    }
    try fm.copyItem(at: archiveURL, to: destArchiveURL)

    log("Copying manifest to \(destManifestURL.path)")
    if fm.fileExists(atPath: destManifestURL.path) {
      try fm.removeItem(at: destManifestURL)
    }
    try fm.copyItem(at: manifestURL, to: destManifestURL)

    let rescanMarkerURL = autoinstallURL.appending(path: ".rescan")
    log("Touching rescan marker")
    try "".write(to: rescanMarkerURL, atomically: true, encoding: .utf8)

    print("Deployed archive and manifest to: \(autoinstallURL.path)")
  }
}
