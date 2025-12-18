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
  @Option(help: "Path to a folder containing mod config .json files.") var modsPath: String?
  @Option(help: "Path to a folder where individual NPC JSON files will be written.")
  var npcsPath: String?
  @Option(help: "Path to a folder where individual outfit JSON files will be written.")
  var outfitsPath: String?

  mutating func run() throws {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    guard let inputPath else {
      print("No input path specified.")
      return
    }

    guard let modsPath else {
      print("No mods path specified.")
      return
    }

    let inputURL = URL(fileURLWithPath: inputPath, relativeTo: cwd)
    let modsURL = URL(fileURLWithPath: modsPath, relativeTo: cwd)
    let fm = FileManager.default

    try fm.createDirectory(at: modsURL, withIntermediateDirectories: true)
    var mods: [String: ModRecord] = [:]
    let decoder = JSONDecoder()
    for modURL in try fm.contentsOfDirectory(at: modsURL, includingPropertiesForKeys: nil) {
      guard modURL.pathExtension.lowercased() == "json" else { continue }
      do {
        let data = try Data(contentsOf: modURL)
        let mod = try decoder.decode(ModRecord.self, from: data)
        mods[modURL.deletingPathExtension().lastPathComponent] = mod
      } catch {
        log("Skipping mod file \(modURL.lastPathComponent): \(error)")
      }
    }

    guard let enumerator = fm.enumerator(at: inputURL, includingPropertiesForKeys: nil) else {
      print("Couldn't enumerate files at \(inputURL.path)")
      return
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let parser = IniParser()
    var people: [String: PersonRecord] = [:]
    var outfits: [String: FormReference] = [:]
    for case let fileURL as URL in enumerator {
      let filename = fileURL.lastPathComponent.trimmingCharacters(in: .whitespaces)
      guard filename.lowercased().hasSuffix("_distr.ini") else { continue }
      log("Parsing \(fileURL.lastPathComponent)")
      let entries = try parser.parse(url: fileURL)
      process(
        entries: entries, people: &people, outfits: &outfits, mods: &mods, modsURL: modsURL,
        encoder: encoder, source: fileURL.lastPathComponent)
    }

    if let npcsPath {
      let npcsURL = URL(fileURLWithPath: npcsPath, relativeTo: cwd)
      try FileManager.default.createDirectory(at: npcsURL, withIntermediateDirectories: true)

      for (name, record) in people {
        let data = try encoder.encode(record)
        let fileURL = npcsURL.appending(path: "\(name).json")
        try data.write(to: fileURL)
      }

      log("Wrote \(people.count) NPC files to \(npcsURL.path)")
    } else {
      let data = try encoder.encode(people)
      if let json = String(data: data, encoding: .utf8) {
        print(json)
      }
    }

    if let outfitsPath {
      let outfitsURL = URL(fileURLWithPath: outfitsPath, relativeTo: cwd)
      try FileManager.default.createDirectory(at: outfitsURL, withIntermediateDirectories: true)

      for (key, record) in outfits {
        let data = try encoder.encode(record)
        let fileURL = outfitsURL.appending(path: "\(key).json")
        try data.write(to: fileURL)
      }

      log("Wrote \(outfits.count) outfit files to \(outfitsURL.path)")
    }
  }

  /// Processes parsed INI entries and extracts outfit assignments.
  ///
  /// - Parameters:
  ///   - entries: Parsed INI entries with preserved preceding comments.
  ///   - people: A mutable dictionary that accumulates person records.
  ///   - outfits: A mutable dictionary of outfits keyed by spidName.
  ///   - source: The name of the source file for logging purposes.
  private func process(
    entries: [IniEntry], people: inout [String: PersonRecord],
    outfits: inout [String: FormReference], mods: inout [String: ModRecord], modsURL: URL,
    encoder: JSONEncoder, source: String
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

      let form: FormReference
      do {
        form = try FormReference(parse: String(formPart), comment: entry.comment)
      } catch {
        log("Skipping malformed form \(formPart): \(error)", path: [source])
        continue
      }

      let names =
        namesPart
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }

      let outfitKey = form.spidName
      outfits[outfitKey] = form

      let modName = URL(fileURLWithPath: form.file).deletingPathExtension().lastPathComponent
      if mods[modName] == nil {
        let record = ModRecord(skipOBody: true)
        mods[modName] = record
        let modFileURL = modsURL.appending(path: "\(modName).json")
        do {
          let data = try encoder.encode(record)
          try data.write(to: modFileURL)
          log("Created mod config for \(modName)", path: [source])
        } catch {
          log("Failed to write mod config for \(modName): \(error)", path: [source])
        }
      }

      for name in names {
        if let existing = people[name]?.outfit, existing != outfitKey {
          log(
            "Overwriting existing entry \"\(existing)\" with \"\(outfitKey)\" for \(name)",
            path: [source])
        }
        people[name] = PersonRecord(outfit: outfitKey)
      }
    }
  }

}
