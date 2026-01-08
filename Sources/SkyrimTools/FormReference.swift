// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Represents a Skyrim outfit reference in a mod.
///
/// This struct contains all the information needed to identify and reference
/// an outfit from a specific mod file.
struct FormReference: Codable, Equatable {
  /// The formID of the outfit as an uppercase hex string with a `0x` prefix.
  let formID: String?

  /// Optional editor ID of the outfit.
  let editorID: String?

  /// The mod filename including extension, eg `FlowerGirlsDESPID.esp`.
  let mod: String?

  /// Optional human-readable name as it appears in the game.
  let name: String?

  /// Optional full description extracted from any preceding comments.
  let description: String?

  enum ParseError: Error {
    case malformedForm(String)
    case invalidFormID(String)
    case unknownModType(String)
  }

  /// Initialize a reference with explicit values.
  init(
    formID: String? = nil, intFormID: UInt? = nil, editorID: String? = nil, mod: String? = nil,
    name: String? = nil,
    description: String? = nil
  ) {
    let id = formID ?? intFormID.map { String(format: "0x%X", $0) }
    self.formID = id?.cleanHex
    self.editorID = editorID
    self.mod = mod
    self.name = name
    self.description = description
  }

  /// Initialize a reference from an ARMA entry.
  init(_ arma: ARMAEntry) {
    self.formID = String(format: "0x%X", arma.formID).cleanHex
    self.editorID = arma.editorID
    self.mod = "zzAlsarOutfitMod.esp"
    self.name = nil
    self.description = nil
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
    self.editorID = nil
    self.mod = modURL.lastPathComponent
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
    guard let mod else { return .esp }
    let ext = URL(fileURLWithPath: mod).pathExtension.lowercased()
    return ModType(rawValue: ext) ?? .esp
  }

  /// Name for use in a SPID or KID file.
  /// Uses the human-readable name if present,
  /// otherwise combines formID and mod.
  var spidReference: String? {
    if let ref = name ?? idModReference {
      return ref
    } else {
      return nil
    }
  }

  /// Combined formID and mod with a ~.
  var idModReference: String? {
    guard let mod else { return nil }
    if let formID { return "\(formID)~\(mod)" }
    return nil
  }

  /// Mod ID for use in calculating the full formID
  /// from the local formID, for DLC esm files.
  var modID: UInt {
    switch mod?.lowercased() {
    case "dawnguard.esm": return 0x0100_0000
    case "dragonborn.esm": return 0x0200_0000
    default: return 0
    }
  }

  /// Name for use in a sleep set file.
  var sleepReference: String? {
    guard let mod else { return nil }
    return formID.map { "\($0)|\(mod)" }
  }

  /// The formID as an integer, if available.
  var intFormID: UInt? {
    guard let formID else { return nil }
    let hexBody = formID.hasPrefix("0x") ? String(formID.dropFirst(2)) : formID
    return UInt(hexBody, radix: 16)
  }

  /// The formID as an 8-character uppercase hex string, if available.
  /// Pads with leading zeros if necessary.
  /// Doesn't include the `0x` prefix.
  var rawFormID8: String? {
    guard let intFormID else { return nil }
    return String(format: "%08X", intFormID)
  }

  /// The full formID including mod offset, if available.
  var fullIntFormID: UInt? {
    guard let intFormID else { return nil }
    return intFormID + modID
  }

}

extension String {
  /// Compare two id~mod references for sorting.
  static func idModReferencesAreIncreasing(_ ref1: String, _ ref2: String) -> Bool {
    let s1 = ref1.split(separator: "~")
    let s2 = ref2.split(separator: "~")
    if let u1 = s1.last, let u2 = s2.last {
      if u1 == u2 {
        if let f1 = s1.first, let f2 = s2.first,
          let u1 = UInt(f1), let u2 = UInt(f2)
        {
          return u1 < u2
        }
      } else {
        return u1 < u2
      }
    }
    return ref1 < ref2
  }
}
