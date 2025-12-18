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

    let inputURL = URL(fileURLWithPath: inputPath, relativeTo: cwd)
    let fm = FileManager.default
    guard let enumerator = fm.enumerator(at: inputURL, includingPropertiesForKeys: nil) else {
      print("Couldn't enumerate files at \(inputURL.path)")
      return
    }

    var people: [String: PersonRecord] = [:]
    var outfits: [String: FormReference] = [:]
    for case let fileURL as URL in enumerator {
      guard fileURL.lastPathComponent.hasSuffix("_DISTR.ini") else { continue }
      log("Parsing \(fileURL.lastPathComponent)")
      let contents = try String(contentsOf: fileURL, encoding: .utf8)
      parse(
        contents: contents, people: &people, outfits: &outfits, source: fileURL.lastPathComponent)
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

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

  /// Parses INI file contents and extracts outfit assignments.
  ///
  /// - Parameters:
  ///   - contents: The raw contents of the INI file as a string.
  ///   - people: A mutable dictionary that accumulates person records.
  ///   - source: The name of the source file for logging purposes.
  private func parse(
    contents: String, people: inout [String: PersonRecord],
    outfits: inout [String: FormReference],
    source: String
  ) {
    var previousNonEmptyLine: String?
    for rawLine in contents.split(whereSeparator: \.isNewline) {
      let line = rawLine.trimmingCharacters(in: .whitespaces)
      guard !line.isEmpty else { continue }

      if line.hasPrefix("Outfit") {

        let parts = line.split(separator: "=", maxSplits: 1).map {
          $0.trimmingCharacters(in: .whitespaces)
        }
        guard parts.count == 2 else {
          log("Skipping malformed line (expected key=value)", path: [source])
          previousNonEmptyLine = line
          continue
        }

        let payload = parts[1]
        let assignment = payload.split(separator: "|", maxSplits: 1).map {
          $0.trimmingCharacters(in: .whitespaces)
        }
        guard assignment.count == 2 else {
          log("Skipping malformed line (expected form|names)", path: [source])
          previousNonEmptyLine = line
          continue
        }

        let formPart = assignment[0]
        let namesPart = assignment[1]
        let commentName = extractName(from: previousNonEmptyLine)

        guard
          let form = parseForm(
            String(formPart), source: source, commentName: commentName
          )
        else {
          previousNonEmptyLine = line
          continue
        }
        let names =
          namesPart
          .split(separator: ",")
          .map { $0.trimmingCharacters(in: .whitespaces) }
          .filter { !$0.isEmpty }

        outfits[form.spidName] = form

        for name in names {
          if let existing = people[name], existing.outfit.formID != form.formID {
            log("Overwriting existing entry for \(name)", path: [source])
          }
          people[name] = PersonRecord(outfit: form)
        }
      }
      previousNonEmptyLine = line
    }
  }

  /// Parses a form record string and returns a FormReference.
  ///
  /// Expected format: `0xHEXID~modname.esp`
  ///
  /// - Parameters:
  ///   - string: The form record string to parse.
  ///   - source: The name of the source file for logging purposes.
  ///   - commentName: Optional human-readable name parsed from a preceding comment.
  /// - Returns: A FormReference if parsing succeeds, nil otherwise.
  private func parseForm(
    _ string: String, source: String, commentName: String?
  ) -> FormReference? {

    let components = string.split(separator: "~", maxSplits: 1).map {
      $0.trimmingCharacters(in: .whitespaces)
    }
    guard components.count == 2 else {
      log("Skipping malformed form (expected id~mod)", path: [source])
      return nil
    }

    let idString = components[0]
    let hexBody = idString.hasPrefix("0x") ? String(idString.dropFirst(2)) : String(idString)
    guard UInt(hexBody, radix: 16) != nil else {
      log("Invalid formID \(idString)", path: [source])
      return nil
    }

    let modString = components[1]
    let modURL = URL(fileURLWithPath: modString)
    let modTypeString = modURL.pathExtension.lowercased()
    guard ModType(rawValue: modTypeString) != nil else {
      log("Unknown mod type for \(modString)", path: [source])
      return nil
    }
    let normalizedFormID = "0x" + hexBody.uppercased()
    return FormReference(
      formID: normalizedFormID, file: modURL.lastPathComponent, name: commentName)
  }

  /// Extracts a human-readable name from a preceding comment line, if present.
  ///
  /// Expected format: `;<name> outfit to <person>`
  private func extractName(from comment: String?) -> String? {
    guard let comment else { return nil }
    let trimmed = comment.trimmingCharacters(in: .whitespaces)
    guard trimmed.hasPrefix(";") else { return nil }

    let bodyString = String(trimmed.dropFirst())
    let lowercasedBody = bodyString.lowercased()
    guard let range = lowercasedBody.range(of: " outfit to ") else { return nil }

    let name = bodyString[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
    return name.isEmpty ? nil : String(name)
  }
}
