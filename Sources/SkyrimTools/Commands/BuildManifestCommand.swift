// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/04/2026.
//  All code (c) 2026 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

/// Builds a Vortex sidecar manifest for a mod archive.
struct BuildManifestCommand: LoggableCommand {

  /// JSON shape for `.vortex.json` sidecar files.
  struct VortexManifest: Encodable {
    /// Display name shown in Vortex.
    let name: String

    /// Version string shown in Vortex.
    let version: String

    /// Stable private plugin identifier.
    let pluginId: String

    /// MD5 checksum of the archive payload.
    let fileMD5: String
  }

  /// Errors for manifest generation.
  enum BuildManifestError: Swift.Error, CustomStringConvertible {
    /// Required field is missing from metadata.
    case missingMetadataField(String)

    /// Archive file does not exist.
    case archiveNotFound(String)

    /// md5sum command failed.
    case md5sumFailed(Int32)

    /// md5sum output was not parseable.
    case invalidMD5Output

    /// User-facing error description.
    var description: String {
      switch self {
      case .missingMetadataField(let field):
        return "Missing required field in mod metadata: \(field)"
      case .archiveNotFound(let path):
        return "Archive file not found: \(path)"
      case .md5sumFailed(let code):
        return "md5sum exited with status code \(code)."
      case .invalidMD5Output:
        return "Unable to parse md5sum output."
      }
    }
  }

  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "build-manifest",
      abstract: "Generate/update a Vortex .vortex.json manifest for a mod archive."
    )
  }

  /// Enable verbose logs.
  @Flag() var verbose: Bool = false

  /// Path to mod JSON that defines content and archive names.
  @Option(help: "Path to mod JSON (e.g. overrides.json).")
  var modPath: String

  /// Build number used as the third component of the version.
  @Option(help: "Build number for manifest version (major.minor.<build-number>).")
  var buildNumber: Int

  /// Run manifest build.
  mutating func run() async throws {
    let fm = FileManager.default
    let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
    let (settings, configURL) = try SkyrimToolsSettings.load(from: cwd)
    let mod = try ModMetadata.load(from: modPath, cwd: cwd)
    let paths = try ModMetadata.derivePaths(settings: settings, configURL: configURL, mod: mod)
    try execute(mod: mod, paths: paths, buildNumber: buildNumber, emitSummary: true)
  }

  /// Write the manifest, optionally printing a summary line.
  mutating func execute(
    mod: ModMetadata,
    paths: ModMetadata.DerivedPaths,
    buildNumber: Int,
    emitSummary: Bool
  ) throws {
    let fm = FileManager.default

    guard fm.fileExists(atPath: paths.archiveURL.path) else {
      throw BuildManifestError.archiveNotFound(paths.archiveURL.path)
    }

    let name = mod.name ?? mod.content
    guard !name.isEmpty else {
      throw BuildManifestError.missingMetadataField("name")
    }

    guard let baseVersion = mod.version, !baseVersion.isEmpty else {
      throw BuildManifestError.missingMetadataField("version")
    }

    let version = try ModMetadata.composeVersion(baseVersion: baseVersion, buildNumber: buildNumber)
    let pluginID = mod.id ?? slug(from: name)
    let fileMD5 = try md5sum(of: paths.archiveURL)

    let manifest = VortexManifest(
      name: name,
      version: version,
      pluginId: pluginID,
      fileMD5: fileMD5
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(manifest)
    try data.write(to: paths.manifestURL)

    log("Wrote \(paths.manifestURL.path)")
    if emitSummary {
      print("Manifest created at: \(paths.manifestURL.path)")
    }
  }

  /// Compute md5sum for a file by invoking the host md5sum utility.
  private func md5sum(of fileURL: URL) throws -> String {
    let process = Process()
    let output = Pipe()

    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["md5sum", fileURL.path]
    process.standardOutput = output
    process.standardError = Pipe()

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
      throw BuildManifestError.md5sumFailed(process.terminationStatus)
    }

    let data = output.fileHandleForReading.readDataToEndOfFile()
    guard let line = String(data: data, encoding: .utf8)?.split(separator: "\n").first else {
      throw BuildManifestError.invalidMD5Output
    }

    let parts = line.split(separator: " ")
    guard let hash = parts.first, hash.count == 32 else {
      throw BuildManifestError.invalidMD5Output
    }

    return String(hash)
  }
  /// Slugify fallback plugin id from a display name.
  private func slug(from string: String) -> String {
    let lower = string.lowercased()
    let replaced = lower.replacing(#/[^a-z0-9]+/#, with: "-")
    return replaced.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
  }
}
