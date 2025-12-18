// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Represents a Skyrim outfit reference in a mod.
///
/// This struct contains all the information needed to identify and reference
/// an outfit from a specific mod file.
struct FormReference: Codable {
  /// The formID of the outfit as an uppercase hex string with a `0x` prefix.
  let formID: String

  /// The plugin filename including extension, eg `FlowerGirlsDESPID.esp`.
  let file: String

  /// Optional human-readable name from a preceding comment, if present.
  let name: String?

  /// Optional full description extracted from any preceding comments.
  let description: String?

  enum ParseError: Error {
    case malformedForm(String)
    case invalidFormID(String)
    case unknownModType(String)
  }

  /// Initialize a reference by parsing a `formID~mod` string.
  /// - Parameters:
  ///   - string: The form record string to parse, eg `0x800~FlowerGirlsDESPID.esp`.
  ///   - comment: Optional human-readable name derived from preceding comments.
  init(parse string: String, comment: String?) throws {
    let components = string.split(separator: "~", maxSplits: 1).map {
      $0.trimmingCharacters(in: .whitespaces)
    }
    guard components.count == 2 else {
      throw ParseError.malformedForm(string)
    }

    let idString = components[0].lowercased()
    let hexBody = idString.hasPrefix("0x") ? String(idString.dropFirst(2)) : String(idString)
    guard UInt(hexBody, radix: 16) != nil else {
      throw ParseError.invalidFormID(idString)
    }

    let modString = components[1]
    let modURL = URL(fileURLWithPath: modString)
    let modTypeString = modURL.pathExtension.lowercased()
    guard ModType(rawValue: modTypeString) != nil else {
      throw ParseError.unknownModType(modString)
    }

    let normalizedFormID = "0x" + hexBody.uppercased()
    self.formID = normalizedFormID
    self.file = modURL.lastPathComponent
    self.description = comment?.isEmpty == false ? comment : nil
    self.name = FormReference.parseName(from: comment)
  }

  /// Attempt to parse a form name from the comment.
  /// Look for the pattern `<name> outfit to <person>`, and use <name>.
  /// Otherwise use the last line of the comment if it exists.
  private static func parseName(from comment: String?) -> String? {
    guard
      let comment,
      !comment.isEmpty
    else { return nil }

    let lines =
      comment
      .split(whereSeparator: \.isNewline)
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }

    guard let line = lines.first else { return nil }

    let regex = #/^(?<name>.+?)\s+outfit\s+to\s+\w+/#
    if let name = line.wholeMatch(of: regex)?.name.trimmingCharacters(in: .whitespaces),
      !name.isEmpty
    {
      return name
    }

    return line
  }

  /// Derived plugin type from the filename extension.
  var modType: ModType {
    let ext = URL(fileURLWithPath: file).pathExtension.lowercased()
    return ModType(rawValue: ext) ?? .esp
  }

  var spidName: String {
    if let name {
      return name
    } else {
      return "\(formID)~\(file)"
    }
  }
}
