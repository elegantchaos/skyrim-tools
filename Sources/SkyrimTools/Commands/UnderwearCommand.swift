// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

struct UnderwearCommand: LoggableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "underwear",
      abstract: "Generate an Underwear.ini from armour flagged for underwear use."
    )
  }

  @Flag() var verbose: Bool = false
  @Option(
    help:
      "Path to the model data folder containing Mods, Outfits, People, and Armors subdirectories.")
  var modelPath: String?
  @Option(help: "Path to write the generated Underwear.ini file to.") var outputPath: String?

  mutating func run() throws {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    guard let modelPath else {
      print("No model path specified.")
      return
    }

    guard let outputPath else {
      print("No output path specified.")
      return
    }

    let modelURL = URL(fileURLWithPath: modelPath, relativeTo: cwd)
    let outputURL = URL(fileURLWithPath: outputPath, relativeTo: cwd)
    let manager = try ModelManager(dataURL: modelURL)

    try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

    let underwearRefs: Set<String> = Set(
      manager.armors.values.compactMap { armor in
        guard armor.useAsUnderwear == true else { return nil }
        guard let ref = armor.id.idModReference else {
          log("Skipping armour missing formID", path: [armor.id.mod ?? "unknown"])
          return nil
        }
        return ref
      }
    )

    let blacklistRefs: Set<String> = Set(
      manager.people.compactMap { (name, person) in
        guard person.blacklistForUnderwear == true else { return nil }
        guard let id = person.id, let ref = id.idModReference else {
          log("Warning: Person \(name) has blacklistForUnderwear but no id", path: [name])
          return nil
        }
        return ref
      }
    )

    let sortedRefs =
      underwearRefs
      .sorted(by: String.idModReferencesAreIncreasing)
      .map { "Underwear = \($0)" }

    let sortedBlacklist =
      blacklistRefs
      .sorted(by: String.idModReferencesAreIncreasing)
      .map { "Ignore = \($0)" }

    var lines: [String] = ["[General]"]
    lines.append(contentsOf: sortedRefs)
    lines.append("")
    lines.append("[Blacklist]")
    lines.append(contentsOf: sortedBlacklist)
    lines.append("")
    lines.append(contentsOf: Self.logSection)

    let content = lines.joined(separator: "\n") + "\n"
    let outputFileURL = outputURL.appending(path: "Underwear.ini")
    try content.write(to: outputFileURL, atomically: true, encoding: .utf8)

    log(
      "Wrote Underwear.ini with \(underwearRefs.count) entries and \(blacklistRefs.count) blacklist items"
    )
  }
}

extension UnderwearCommand {
  /// Static log section matching the example file.
  static let logSection: [String] = [
    "[Log]",
    "Debug = false",
  ]
}
