// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A record representing an NPC person with their outfit assignment.
struct PersonRecord: Codable, Equatable {
  /// Outfit filename (without extension) that this NPC uses.
  var outfit: String?
  /// Optional source identifier for where the outfit came from.
  /// For example, the INI filename or mod name.
  var outfitSource: String? = nil
}
