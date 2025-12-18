// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A record representing an NPC person with their outfit assignment.
struct PersonRecord: Codable, Equatable {
  /// Outfit filename (without extension) that this NPC uses.
  var outfit: String?

  /// Where the outfit came from.
  /// For example, the INI filename or mod name.
  var outfitSource: String? = nil

  /// Any outfit collisions for this NPC.
  /// Each tuple contains (outfit name, outfit source)
  /// for an outfit that conflicts with the assigned one.
  var outfitCollisions: [OutfitCollision]? = nil
}

struct OutfitCollision: Codable, Equatable, Hashable {
  let outfit: String
  let source: String
}
