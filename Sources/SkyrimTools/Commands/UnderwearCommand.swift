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
        guard let formID = armor.id.formID else {
          log("Skipping armour missing formID", path: [armor.id.mod])
          return nil
        }
        return "\(formID)~\(armor.id.mod)"
      }
    )

    let blacklistRefs: Set<String> = Set(
      manager.people.compactMap { (name, person) in
        guard person.blacklistForUnderwear == true else { return nil }
        guard let id = person.id, let formID = id.formID else {
          log("Warning: Person \(name) has blacklistForUnderwear but no id", path: [name])
          return nil
        }
        return "\(formID)~\(id.mod)"
      }
    )

    let sortedRefs =
      underwearRefs
      .sorted {
        let s1 = $0.split(separator: "~")
        let s2 = $1.split(separator: "~")
        if let u1 = s1.last, let u2 = s2.last {
          if u1 == u2 {
            if let f1 = s1.first, let f2 = s2.first,
              let u1 = UInt(f1), let u2 = UInt(f2)
            {
              return u1 < u2
            }
          } else {
            return u1 < u2
          }
        }
        return $0 < $1
      }
      .map { "Underwear = \($0)" }

    let sortedBlacklist =
      blacklistRefs
      .sorted {
        let s1 = $0.split(separator: "~")
        let s2 = $1.split(separator: "~")
        if let u1 = s1.last, let u2 = s2.last {
          if u1 == u2 {
            if let f1 = s1.first, let f2 = s2.first,
              let u1 = UInt(f1), let u2 = UInt(f2)
            {
              return u1 < u2
            }
          } else {
            return u1 < u2
          }
        }
        return $0 < $1
      }
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
