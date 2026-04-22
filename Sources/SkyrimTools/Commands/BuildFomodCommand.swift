// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/04/2026.
//  All code (c) 2026 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

/// Builds `fomod/info.xml` and `fomod/ModuleConfig.xml` for a mod.
struct BuildFomodCommand: LoggableCommand {

  /// Errors for fomod generation.
  enum BuildFomodError: Swift.Error, CustomStringConvertible {
    /// Required field is missing from metadata.
    case missingMetadataField(String)

    /// User-facing error description.
    var description: String {
      switch self {
      case .missingMetadataField(let field):
        return "Missing required field in mod metadata: \(field)"
      }
    }
  }

  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "build-fomod",
      abstract: "Generate/update fomod metadata files for a mod."
    )
  }

  /// Enable verbose logs.
  @Flag() var verbose: Bool = false

  /// Path to mod JSON that defines content and archive names.
  @Option(help: "Path to mod JSON (e.g. overrides.json).")
  var modPath: String

  /// Build number used as the third component of the version.
  @Option(help: "Build number for info.xml version (major.minor.<build-number>).")
  var buildNumber: Int

  /// Run fomod build.
  mutating func run() async throws {
    try execute(emitSummary: true)
  }

  /// Generate fomod files, optionally printing the summary line.
  mutating func execute(emitSummary: Bool) throws {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let (settings, configURL) = try SkyrimToolsSettings.load(from: cwd)
    let mod = try ModMetadata.load(from: modPath, cwd: cwd)
    let paths = try ModMetadata.derivePaths(settings: settings, configURL: configURL, mod: mod)

    let name = mod.name ?? mod.content
    let author = mod.author ?? ""
    let description = mod.description ?? ""
    let website = mod.website ?? ""
    let pluginID = mod.id ?? slug(from: name)

    guard !name.isEmpty else {
      throw BuildFomodError.missingMetadataField("name")
    }

    guard let baseVersion = mod.version, !baseVersion.isEmpty else {
      throw BuildFomodError.missingMetadataField("version")
    }

    let versionString = try ModMetadata.composeVersion(
      baseVersion: baseVersion,
      buildNumber: buildNumber
    )

    let fomodURL = paths.stagingURL.appending(path: "fomod")
    let infoURL = fomodURL.appending(path: "info.xml")
    let moduleConfigURL = fomodURL.appending(path: "ModuleConfig.xml")

    let infoXML = """
      <?xml version="1.0" encoding="UTF-8"?>
      <fomod>
        <Name>\(xmlEscaped(name))</Name>
        <Author>\(xmlEscaped(author))</Author>
        <Version MachineVersion="\(xmlEscaped(versionString))">\(xmlEscaped(versionString))</Version>
        <Description>\(xmlEscaped(description))</Description>
        <Website>\(xmlEscaped(website))</Website>
        <Id>\(xmlEscaped(pluginID))</Id>
      </fomod>
      """

    let moduleConfigXML = """
      <?xml version="1.0" encoding="UTF-8"?>
      <config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:noNamespaceSchemaLocation="http://qconsulting.ca/fo3/ModConfig5.0.xsd">
        <moduleName>\(xmlEscaped(name))</moduleName>
        <requiredInstallFiles>
          <folder source="Data" destination="" priority="0" />
        </requiredInstallFiles>
      </config>
      """

    log("Writing \(infoURL.path)")
    try infoXML.write(to: infoURL)
    log("Writing \(moduleConfigURL.path)")
    try moduleConfigXML.write(to: moduleConfigURL)

    if emitSummary {
      print("Generated fomod files in: \(fomodURL.path)")
    }
  }

  /// Escape XML entities for element and attribute values.
  private func xmlEscaped(_ string: String) -> String {
    string
      .replacing("&", with: "&amp;")
      .replacing("<", with: "&lt;")
      .replacing(">", with: "&gt;")
      .replacing("\"", with: "&quot;")
      .replacing("'", with: "&apos;")
  }

  /// Slugify fallback plugin id from a display name.
  private func slug(from string: String) -> String {
    let lower = string.lowercased()
    let replaced = lower.replacing(#/[^a-z0-9]+/#, with: "-")
    return replaced.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
  }
}
