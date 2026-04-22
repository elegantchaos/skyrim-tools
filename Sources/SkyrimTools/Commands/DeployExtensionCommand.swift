// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/04/2026.
//  All code (c) 2026 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

/// Deploys the configured Vortex extension into the Vortex plugins directory.
struct DeployExtensionCommand: LoggableCommand {

  /// Domain errors for extension deployment.
  enum DeployExtensionError: Swift.Error, CustomStringConvertible {
    /// Required key is missing from config.
    case missingPath(String)

    /// Source path does not exist.
    case sourcePathMissing(String)

    /// Source path exists but is not a directory.
    case sourcePathIsNotDirectory(String)

    /// User-facing error description.
    var description: String {
      switch self {
      case .missingPath(let key):
        return "Missing required path in skyrim-tools.json: paths.\(key)"
      case .sourcePathMissing(let path):
        return "Configured extension source path does not exist: \(path)"
      case .sourcePathIsNotDirectory(let path):
        return "Configured extension source path is not a directory: \(path)"
      }
    }
  }

  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "deploy-extension",
      abstract: "Deploy the configured Vortex extension into the Vortex plugins folder."
    )
  }

  /// Enable verbose logs.
  @Flag() var verbose: Bool = false

  /// Run the deployment.
  mutating func run() async throws {
    let fm = FileManager.default
    let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
    let (settings, configURL) = try SkyrimToolsSettings.load(from: cwd)
    let vortexPaths = settings.paths.vortex

    guard let sourcePath = vortexPaths?.extension else {
      throw DeployExtensionError.missingPath("vortex.extension")
    }

    guard let pluginsPath = vortexPaths?.plugins else {
      throw DeployExtensionError.missingPath("vortex.plugins")
    }

    let sourceURL = SkyrimToolsSettings.resolve(sourcePath, relativeTo: configURL)
    let pluginsURL = SkyrimToolsSettings.resolve(pluginsPath, relativeTo: configURL)

    var isDirectory: ObjCBool = false
    guard fm.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory) else {
      throw DeployExtensionError.sourcePathMissing(sourceURL.path)
    }

    guard isDirectory.boolValue else {
      throw DeployExtensionError.sourcePathIsNotDirectory(sourceURL.path)
    }

    let destinationURL = pluginsURL.appending(path: sourceURL.lastPathComponent)
    try fm.createDirectory(at: pluginsURL, withIntermediateDirectories: true)

    if fm.fileExists(atPath: destinationURL.path) {
      log("Removing existing extension at \(destinationURL.path)")
      try fm.removeItem(at: destinationURL)
    }

    log("Copying extension from \(sourceURL.path) to \(destinationURL.path)")
    try fm.copyItem(at: sourceURL, to: destinationURL)
    print("Extension deployed to: \(destinationURL.path)")
  }
}
