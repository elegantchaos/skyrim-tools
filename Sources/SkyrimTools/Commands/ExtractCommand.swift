// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

/// Extracts outfit assignments from Skyrim distribution INI files.
///
/// This command scans a directory for files matching the pattern `*_DISTR.ini`
/// and parses outfit assignment lines. Each outfit assignment maps NPC names
/// to specific outfit form records, with the results written to JSON.
struct ExtractCommand: LoggableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "extract",
      abstract: "Extract outfit assignments from distribution INI files."
    )
  }

  @Flag() var verbose: Bool = false
  @Option(help: "Path to a folder containing *_DISTR.ini files.") var inputPath: String?
  @Option(
    help:
      "Path to the model data folder containing Mods, Outfits, People, and Armors subdirectories.")
  var modelPath: String?

  mutating func run() throws {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    guard let inputPath else {
      print("No input path specified.")
      return
    }

    guard let modelPath else {
      print("No model path specified.")
      return
    }

    let inputURL = URL(fileURLWithPath: inputPath, relativeTo: cwd)
    let modelURL = URL(fileURLWithPath: modelPath, relativeTo: cwd)
    let fm = FileManager.default

    let manager = try ModelManager(dataURL: modelURL)

    guard let enumerator = fm.enumerator(at: inputURL, includingPropertiesForKeys: nil) else {
      print("Couldn't enumerate files at \(inputURL.path)")
      return
    }

    let parser = IniParser()
    for case let fileURL as URL in enumerator {
      let filename = fileURL.lastPathComponent.trimmingCharacters(in: .whitespaces)
      guard filename.lowercased().hasSuffix("_distr.ini") else { continue }
      log("Parsing \(fileURL.lastPathComponent)")
      let entries = try parser.parse(url: fileURL)
      process(entries: entries, manager: manager, source: fileURL.lastPathComponent)
    }

    try manager.save()
    log("Model saved to \(modelURL.path)")
  }

  /// Processes parsed INI entries and extracts outfit assignments.
  ///
  /// - Parameters:
  ///   - entries: Parsed INI entries with preserved preceding comments.
  ///   - manager: The model manager for storing records.
  ///   - source: The name of the source file for logging purposes.
  private func process(
    entries: [IniEntry], manager: ModelManager, source: String
  ) {
    for entry in entries.filter({ $0.matchesKey("Outfit") }) {
      let payload = entry.value
      let assignment = payload.split(separator: "|", maxSplits: 1).map {
        $0.trimmingCharacters(in: .whitespaces)
      }
      guard assignment.count == 2 else {
        log("Skipping malformed line (expected form|names)", path: [source])
        continue
      }

      let formPart = assignment[0]
      let namesPart = assignment[1]

      var outfit: FormReference
      do {
        let defaultOutfit = try FormReference(parse: String(formPart), comment: entry.comment)
        let outfitKey = defaultOutfit.spidName
        outfit = manager.outfit(outfitKey, default: { defaultOutfit })
        if outfit != defaultOutfit {
          log("Overwriting existing outfit \(outfit) with \(defaultOutfit)", path: [source])
          manager.updateOutfit(outfitKey, defaultOutfit)
          outfit = defaultOutfit
        }
      } catch {
        log("Skipping malformed form \(formPart): \(error)", path: [source])
        continue
      }

      let names =
        namesPart
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }

      let modName = URL(fileURLWithPath: outfit.file).deletingPathExtension().lastPathComponent
      _ = manager.mod(modName, default: { ModRecord(skipOBody: true) })

      let outfitKey = outfit.spidName
      for name in names {
        var person = manager.person(
          name, default: { PersonRecord(outfit: outfitKey, outfitSource: source) })
        if (person.outfit != outfitKey) || (person.outfitSource != source) {
          log(
            "Overwriting existing entry \"\(person.outfit ?? "")\" with \"\(outfitKey)\" for \(name)",
            path: [source]
          )
          person.outfit = outfitKey
          person.outfitSource = source
          manager.updatePerson(name, person)
        }
      }
    }
  }

}
