// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/04/2026.
//  All code (c) 2026 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Top-level settings loaded from `skyrim-tools.json`.
struct SkyrimToolsSettings: Decodable {

  /// Paths used by command workflows.
  struct Paths: Decodable {
    /// Path to the staging root folder containing mod repositories.
    let staging: String?

    /// Vortex-related paths.
    struct Vortex: Decodable {
      /// Path to the Vortex extension source folder.
      let `extension`: String?

      /// Path to the Vortex plugins root folder.
      let plugins: String?

      /// Path to the Vortex AutoInstall folder.
      let autoinstall: String?
    }

    /// Vortex path settings.
    let vortex: Vortex?
  }

  /// The configured paths.
  let paths: Paths

  /// Load settings from a config file named `skyrim-tools.json` in the provided directory.
  static func load(from directory: URL) throws -> (settings: SkyrimToolsSettings, configURL: URL) {
    let configURL = directory.appending(path: "skyrim-tools.json")
    let data = try Data(contentsOf: configURL)
    let settings = try JSONDecoder().decode(SkyrimToolsSettings.self, from: data)
    return (settings, configURL)
  }

  /// Resolve a path string to a URL.
  ///
  /// Absolute paths are used directly; relative paths are resolved against
  /// the parent directory of the settings file.
  static func resolve(_ path: String, relativeTo configURL: URL) -> URL {
    if path.hasPrefix("/") {
      return URL(fileURLWithPath: path)
    }

    return configURL.deletingLastPathComponent().appending(path: path)
  }
}
