// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/12/25.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

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
struct ExtractORFCommand: LoggableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "extract-orf",
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

    log("Scanning for ORF configuration files in \(inputPath)...")

    let inputURL = URL(fileURLWithPath: inputPath, relativeTo: cwd)
    let modelURL = URL(fileURLWithPath: modelPath, relativeTo: cwd)
    let fm = FileManager.default

    let manager = try ModelManager(dataURL: modelURL)
    let parser = IniParser()
    for fileURL in try fm.contentsOfDirectory(
      at: inputURL, includingPropertiesForKeys: nil)
    {
      let filename = fileURL.lastPathComponent
      guard filename.lowercased().hasSuffix(" orf_kid.ini") else { continue }
      log("Parsing \(fileURL.lastPathComponent)")
      let entries = try parser.parse(url: fileURL)
      process(entries: entries, manager: manager, source: filename)
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
    for entry in entries.filter({ $0.matchesKey("Keyword") }) {
      let values = entry.value
        .split(separator: "|")
        .map {
          $0.trimmingCharacters(in: .whitespaces)
        }

      switch values.count {
      case 3:
        let kind = values[1]
        if kind == "Armor" {
          let keyword = keyword(forORFKeyword: values[0])
          let armors = values[2]
            .split(separator: ",")
            .map {
              $0.trimmingCharacters(in: .whitespaces)
            }

          for armor in armors {
            let editorID = armor.trimmingCharacters(in: .whitespaces)
            var record = manager.armor(
              editorID: editorID,
              default: { key in newArmorRecord(key: key, editorID: editorID) })
            var keywords = record.keywords ?? Set<Keyword>()
            if let keyword {
              keywords.insert(keyword)
              keywords.insert(.orf)
              record.keywords = keywords
              manager.updateArmor(editorID: editorID, record)
            }
          }
        }

      default:
        log("Skipping malformed outfit assignment \(entry.value)", path: [source])
      }
    }
  }

  func newArmorRecord(key: String, editorID: String) -> ArmorRecord {
    if verbose {
      log("Creating new armor record \(editorID)")
    }
    let reference = FormReference(editorID: editorID)
    return ArmorRecord(id: reference)
  }

  func keyword(forORFKeyword orfKeyword: String) -> Keyword? {
    guard let mapped = Self.orfKeywords[orfKeyword] else {
      log("Unknown ORF keyword: \(orfKeyword)")
      return nil
    }

    return mapped
  }

  static let orfKeywords: [String: Keyword] = [
    // No corresponding ORF keywords for these:
    // "ORF_Heavy": .heavy,
    // "ORF_Light": .light,
    // "ORF_Clothing": .clothing,
    // "ORF_Mask": .mask,

    "ORF_Black": .black,
    "ORF_Blue": .blue,
    "ORF_Bra": .bra,
    "ORF_Brown": .brown,
    "ORF_Classy": .classy,
    "ORF_Cleavage": .cleavage,
    "ORF_Colourful": .colourful,
    "ORF_Dress": .dress,
    "ORF_Flimsy": .flimsy,
    "ORF_Gold": .gold,
    "ORF_Green": .green,
    "ORF_Grey": .grey,
    "ORF_Hooded": .hooded,
    "ORF_Intimidating": .intimidating,
    "ORF_Leather": .leather,
    "ORF_NearlyNaked": .indecent,
    "ORF_OutOfPlace": .anachronistic,
    "ORF_Pink": .pink,
    "ORF_Purple": .purple,
    "ORF_Red": .red,
    "ORF_Revealing": .revealing,
    "ORF_Robes": .robes,
    "ORF_Scruffy": .scruffy,
    "ORF_ShortSkirt": .short,
    "ORF_Silver": .silver,
    "ORF_Sturdy": .sturdy,
    "ORF_Tight": .tight,
    "ORF_Underwear": .underwear,
    "ORF_White": .white,
    "ORF_Yellow": .yellow,
    "ORF_Transparent": .transparent,
    "ORF_Inappropriate": .inappropriate,
    "ORF_FromOtherGame": .crossover,
  ]
}
