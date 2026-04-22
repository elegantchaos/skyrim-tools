// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/04/2026.
//  All code (c) 2026 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Metadata that describes a mod archive build/deploy unit.
struct ModMetadata: Decodable {
  /// Folder name for the deployed mod repository under the staging root.
  let mod: String

  /// Folder name under the deployed root that should be archived.
  let content: String

  /// Archive filename to produce and deploy.
  let archive: String

  /// Stable plugin identifier used for private archive updates.
  let id: String?

  /// Display version string for installer metadata.
  let version: String?

  /// Display name for installer metadata.
  let name: String?

  /// Description shown in installer metadata.
  let description: String?

  /// Author shown in installer metadata.
  let author: String?

  /// Project or support website for installer metadata.
  let website: String?

  /// Fully resolved paths derived from mod metadata and settings.
  struct DerivedPaths {
    /// Staging folder path.
    let stagingURL: URL

    /// Archive output/input path.
    let archiveURL: URL

    /// Sidecar manifest path.
    let manifestURL: URL
  }

  /// Errors for mod metadata loading and path derivation.
  enum MetadataError: Swift.Error, CustomStringConvertible {
    /// Required key is missing from config.
    case missingPath(String)

    /// Metadata version format is invalid.
    case invalidVersion(String)

    /// User-facing error description.
    var description: String {
      switch self {
      case .missingPath(let key):
        return "Missing required path in skyrim-tools.json: paths.\(key)"
      case .invalidVersion(let value):
        return "Invalid mod metadata version '\(value)'. Expected at least major.minor"
      }
    }
  }

  /// Load mod metadata JSON from a path or bare name relative to the current working directory.
  ///
  /// If the supplied string contains no path separator and does not end in `.json`, it is treated
  /// as a bare name and resolved as `<name>.json` in the working directory.
  static func load(from modPath: String, cwd: URL) throws -> ModMetadata {
    let resolvedPath: String
    if !modPath.contains("/") && !modPath.hasSuffix(".json") {
      resolvedPath = modPath + ".json"
    } else {
      resolvedPath = modPath
    }
    let modURL: URL
    if resolvedPath.hasPrefix("/") {
      modURL = URL(fileURLWithPath: resolvedPath)
    } else {
      modURL = cwd.appending(path: resolvedPath)
    }

    let data = try Data(contentsOf: modURL)
    return try JSONDecoder().decode(ModMetadata.self, from: data)
  }

  /// Derive staging/archive/manifest paths from settings and mod metadata.
  static func derivePaths(settings: SkyrimToolsSettings, configURL: URL, mod: ModMetadata)
    throws -> DerivedPaths
  {
    guard let stagingRootPath = settings.paths.staging else {
      throw MetadataError.missingPath("staging")
    }

    let stagingRootURL = try SkyrimToolsSettings.resolveConfiguredPath(
      stagingRootPath,
      relativeTo: configURL
    )
    let modRootURL = stagingRootURL.appending(path: mod.mod)
    let stagingURL = modRootURL.appending(path: mod.content)
    let archiveURL = modRootURL.appending(path: mod.archive)
    let manifestURL = URL(fileURLWithPath: archiveURL.path + ".vortex.json")

    return DerivedPaths(stagingURL: stagingURL, archiveURL: archiveURL, manifestURL: manifestURL)
  }

  /// Compose a release version from metadata major/minor and a build number.
  static func composeVersion(baseVersion: String, buildNumber: Int) throws -> String {
    let components = baseVersion.split(separator: ".")
    guard components.count >= 2 else {
      throw MetadataError.invalidVersion(baseVersion)
    }

    let major = String(components[0])
    let minor = String(components[1])
    return "\(major).\(minor).\(buildNumber)"
  }
}
