// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/12/25.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation
import SwiftESP

/// Extracts outfit assignments from Skyrim distribution INI files.
///
/// This command scans a directory for files matching the pattern `*_DISTR.ini`
/// and parses outfit assignment lines. Each outfit assignment maps NPC names
/// to specific outfit form records, with the results written to JSON.
struct ExtractArmorCommand: LoggableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "extract-armor",
      abstract: "Extract armor records from ESP files."
    )
  }

  @Flag() var verbose: Bool = false
  @Option(help: "Path to a folder containing *.esp files.") var inputPath: String?
  @Option(
    help:
      "Path to the model data folder containing Mods, Outfits, People, and Armors subdirectories.")
  var modelPath: String?

  mutating func run() async throws {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    guard let inputPath else {
      print("No input path specified.")
      return
    }

    guard let modelPath else {
      print("No model path specified.")
      return
    }

    log("Scanning for ESP files in \(inputPath)...")

    let inputURL = URL(fileURLWithPath: inputPath, relativeTo: cwd)
    let modelURL = URL(fileURLWithPath: modelPath, relativeTo: cwd)
    let fm = FileManager.default

    let model = try ModelManager(dataURL: modelURL)
    // let parser = IniParser()
    let extensions = ["esp", "esm", "esl"]
    for fileURL in try fm.contentsOfDirectory(
      at: inputURL, includingPropertiesForKeys: nil)
    {
      guard extensions.contains(fileURL.pathExtension.lowercased()) else { continue }
      log("Processing \(fileURL.lastPathComponent)")
      let processor = Processor()
      do {
        let records = try await processor.unpack(url: fileURL)
        if let armors = records.index["ARMO"] {
          for armor in armors.compactMap({ $0 as? ARMORecord })
          print(armors)
        }
      } catch {
      }
    }

    try model.save()
    log("Model saved to \(modelURL.path)")
  }

}
