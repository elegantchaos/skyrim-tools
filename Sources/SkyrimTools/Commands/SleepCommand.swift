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

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    // Group armor records by their sleep sets
    var setToArmors: [String: [FormReference]] = [:]
    for (_, armor) in manager.armors {
      guard let sets = armor.sleepSets else { continue }
      for set in sets {
        setToArmors[set, default: []].append(armor.id)
      }
    }

    // Write JSON for each sleep set
    for (setName, armors) in setToArmors {
      let ids =
        armors
        .sorted { FormReference.isIncreasing($0, $1) }
        .compactMap { $0.sleepReference }

      var sleepSet = manager.sleepSet(
        setName, default: { manager.sleepSet("default") ?? SleepSet.empty })
      sleepSet.formList.items = ids

      let data = try encoder.encode(sleepSet)
      let fileName = setName.keyEscapingSlashes + ".json"
      let fileURL = outputURL.appending(path: fileName)
      try data.write(to: fileURL)
      log("Wrote \(setName) with \(ids.count) armours to \(fileName)")
    }
  }
}
