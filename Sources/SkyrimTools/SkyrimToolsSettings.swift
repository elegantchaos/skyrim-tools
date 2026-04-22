// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/04/2026.
//  All code (c) 2026 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Top-level settings loaded from `skyrim-tools.json`.
struct SkyrimToolsSettings: Decodable {

  /// Errors related to configured path resolution.
  enum SettingsError: Swift.Error, CustomStringConvertible {
    /// A settings-derived path resolved outside the allowed test sandbox.
    case unsafePathInTests(String)

    /// User-facing error description.
    var description: String {
      switch self {
      case .unsafePathInTests(let path):
        return
          "Refusing to use configured path while running tests: \(path). Tests must use temporary sandbox paths, not live game or Vortex folders."
      }
    }
  }

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

  /// Resolve a settings-derived path and reject live folders when tests are running.
  static func resolveConfiguredPath(_ path: String, relativeTo configURL: URL) throws -> URL {
    let resolved = resolve(path, relativeTo: configURL).standardizedFileURL
    try validateTestSandbox(for: resolved)
    return resolved
  }

  /// Validate that test runs only use temporary sandbox paths for settings-driven I/O.
  private static func validateTestSandbox(for url: URL) throws {
    guard isRunningUnderTests else {
      return
    }

    let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).standardizedFileURL
    let candidate = url.standardizedFileURL.path
    let tempPath = tempRoot.path
    guard candidate == tempPath || candidate.hasPrefix(tempPath + "/") else {
      throw SettingsError.unsafePathInTests(candidate)
    }
  }

  /// Whether the current process is running under the Swift test harness.
  private static var isRunningUnderTests: Bool {
    getenv("XCTestConfigurationFilePath") != nil
      || environmentValue(named: "SKYRIM_TOOLS_FORCE_TEST_SANDBOX") == "1"
  }

  /// Read a process environment variable directly from libc.
  private static func environmentValue(named name: String) -> String? {
    guard let value = getenv(name) else {
      return nil
    }

    return String(cString: value)
  }
}
