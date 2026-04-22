// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/04/2026.
//  All code (c) 2026 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import TestData
import Testing

@testable import SkyrimTools

@Suite struct SkyrimToolsSettingsTests {

  @Test func resolveConfiguredPathAllowsTemporaryPathsInTests() throws {
    let root = try makeTempDirectory()
    let configURL = root.appending(path: "skyrim-tools.json")
    let outputURL = root.appending(path: "AutoInstall")

    setenv("SKYRIM_TOOLS_FORCE_TEST_SANDBOX", "1", 1)
    defer { unsetenv("SKYRIM_TOOLS_FORCE_TEST_SANDBOX") }

    let resolved = try SkyrimToolsSettings.resolveConfiguredPath(
      outputURL.path, relativeTo: configURL)
    #expect(resolved.standardizedFileURL == outputURL.standardizedFileURL)
  }

  @Test func resolveConfiguredPathRejectsLiveLookingPathsInTests() throws {
    let root = try makeTempDirectory()
    let configURL = root.appending(path: "skyrim-tools.json")

    setenv("SKYRIM_TOOLS_FORCE_TEST_SANDBOX", "1", 1)
    defer { unsetenv("SKYRIM_TOOLS_FORCE_TEST_SANDBOX") }

    #expect(throws: SkyrimToolsSettings.SettingsError.self) {
      try SkyrimToolsSettings.resolveConfiguredPath(
        "/mnt/e/Steam/steamapps/common/Skyrim Special Edition/Data",
        relativeTo: configURL
      )
    }
  }
}
