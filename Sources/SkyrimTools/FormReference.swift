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
