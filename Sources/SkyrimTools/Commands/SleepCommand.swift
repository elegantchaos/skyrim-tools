// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/11/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import DictionaryMerger
import Foundation

struct SleepCommand: ModProcessingCommand {
  typealias ModRecord = SkyrimTools.ModRecord

  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "sleep",
      abstract: "Export sleep information for the armour we know about."
    )
  }

  @Flag() var verbose: Bool = false
  @Option(help: "Path to a folder containing mod data files.") var modsPath: String?
  @Option(help: "Path to write the output files to.") var outputPath: String?

  mutating func run() throws {
    try loadAndProcessMods()
  }

  func process(mods: [String: ModRecord], cwd: URL) {
    if let outputURL = outputPath.map({ URL(fileURLWithPath: $0, relativeTo: cwd) }) {
      for (mod, info) in mods {
        if let armours = info.armours {
          log("Processing \(mod) with \(armours.count) armours")
          let ids = armours.compactMap { $0.formID }
          let json = json(forIDs: ids, mod: mod)
          try? json.write(to: outputURL.appending(path: "\(mod).json"))
        }
      }
    }
  }

  func json(forIDs ids: [String], mod: String) -> String {
    let items = ids.map { id in "          \"\(id.cleanHex)|\(mod)\"" }
    let expanded = items.joined(separator: ",\n")
    return """
        {
          "formList": {
              "items": [
      \(expanded)
              ]
          },
          "int": {
              "itemmode": 0,
              "version": 110
          }
      }
      """
  }
}

extension String {
  var cleanHex: String {
    var cleaned = self
    if cleaned.hasPrefix("0x") {
      cleaned.removeFirst(2)
    }

    if let i = Int(self, radix: 16) {
      if i & 0xFF00_0000 == 0xFF00_0000 {
        return String(format: "0x%X", i & 0xFFFF)
      } else {
        return String(format: "0x%X", i & 0xFFFFFF)
      }
    }

    while cleaned.hasPrefix("0") {
      cleaned.removeFirst()
    }
    return "0x" + cleaned.uppercased()
  }
}
