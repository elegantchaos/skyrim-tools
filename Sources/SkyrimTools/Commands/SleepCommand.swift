// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/11/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

struct SleepCommand: LoggableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "sleep",
      abstract: "Export sleep information for the armour we know about."
    )
  }

  @Flag() var verbose: Bool = false
  @Option(
    help:
      "Path to the model data folder containing Mods, Outfits, People, and Armors subdirectories.")
  var modelPath: String?
  @Option(help: "Path to write the output files to.") var outputPath: String?

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

    // Group armor records by their sleep sets
    var setToArmors: [String: [(id: FormReference, set: String)]] = [:]
    for (_, armor) in manager.armors {
      if let sets = armor.sleepSets {
        for set in sets {
          if setToArmors[set] == nil {
            setToArmors[set] = []
          }
          setToArmors[set]?.append((id: armor.id, set: set))
        }
      }
    }

    // Write JSON for each sleep set
    for (setName, armors) in setToArmors {
      let ids = armors.compactMap { $0.id.sleepName }
      let json = json(forIDs: ids)
      let fileName = setName.keyEscapingSlashes + ".json"
      let fileURL = outputURL.appending(path: fileName)
      try json.write(to: fileURL, atomically: true, encoding: .utf8)
      log("Wrote \(setName) with \(ids.count) armours to \(fileName)")
    }
  }

  func json(forIDs ids: [String]) -> String {
    let items = ids.map { id in "          \"\(id)\"" }
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
