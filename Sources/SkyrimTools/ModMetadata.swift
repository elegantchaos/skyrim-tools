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

    /// User-facing error description.
    var description: String {
      switch self {
      case .missingPath(let key):
        return "Missing required path in skyrim-tools.json: paths.\(key)"
      }
    }
  }

  /// Load mod metadata JSON from a path relative to the current working directory.
  static func load(from modPath: String, cwd: URL) throws -> ModMetadata {
    let modURL: URL
    if modPath.hasPrefix("/") {
      modURL = URL(fileURLWithPath: modPath)
    } else {
      modURL = cwd.appending(path: modPath)
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

    let stagingRootURL = SkyrimToolsSettings.resolve(stagingRootPath, relativeTo: configURL)
    let modRootURL = stagingRootURL.appending(path: mod.mod)
    let stagingURL = modRootURL.appending(path: mod.content)
    let archiveURL = modRootURL.appending(path: mod.archive)
    let manifestURL = URL(fileURLWithPath: archiveURL.path + ".vortex.json")

    return DerivedPaths(stagingURL: stagingURL, archiveURL: archiveURL, manifestURL: manifestURL)
  }
}
