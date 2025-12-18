// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/11/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

struct ModsCommand: ModProcessingCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "mods",
      abstract: "Apply multiple mod configurations."
    )
  }

  struct ModRecord: Codable {
    /// Should we add the mod to the blacklist for OBody?
    let skipOBody: Bool?

    /// Should we add the mod to the blacklist for OBody female?
    let skipOBodyFemale: Bool?

    /// Should we add the mod to the blacklist for OBody male?
    let skipOBodyMale: Bool?

    /// Should we add the mod to the blacklist for RSV?
    let skipRSV: Bool?
  }

  @Flag() var verbose: Bool = false
  @Option(help: "Path to a folder containing mod data files.") var modsPath: String?
  @Option(help: "Path to the output .json file for RSV data.") var rsvOutputPath: String?
  @Option(help: "Path to the output .ini for OBody data.") var obodyOutputPath: String?

  mutating func run() throws {
    log("Processing mods...")
    try loadAndProcessMods()
    log("Done.")
  }

  func process(mods: [String: ModRecord], cwd: URL) {
    var obodyFemaleIds: [String] = []
    var obodyMaleIds: [String] = []
    for (mod, info) in mods {
      var processed = false
      if info.skipOBodyFemale == true || info.skipOBody == true {
        obodyFemaleIds.append(mod)
        processed = true
      }
      if info.skipOBodyMale == true || info.skipOBody == true {
        obodyMaleIds.append(mod)
        processed = true
      }

      if processed {
        log("Processing \(mod)")
      }

    }

    if let outputURL = obodyOutputPath.map({ URL(fileURLWithPath: $0, relativeTo: cwd) }) {
      processOBody(maleIDs: obodyMaleIds, femaleIDs: obodyFemaleIds, to: outputURL)
    }
  }

  func processOBody(maleIDs: [String], femaleIDs: [String], to url: URL) {
    let maleIdList =
      maleIDs
      .sorted()
      .map { "\n      \"\($0)\"" }
      .joined(separator: ",")

    let femaleIdList =
      femaleIDs
      .sorted()
      .map { "\n      \"\($0)\"" }
      .joined(separator: ",")

    let ini = """
      {
          "blacklistedNpcsPluginFemale" : [\(femaleIdList)
          ],
          "blacklistedNpcsPluginMale" : [\(maleIdList)
          ]
      }
      """

    do {
      try ini.write(to: url)
    } catch {
      print("Error writing OBody INI file: \(error)")
    }
  }
}
