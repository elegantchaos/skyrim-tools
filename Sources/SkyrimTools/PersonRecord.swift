// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A record representing an NPC person with their outfit assignment.
struct PersonRecord: Codable, Equatable {
  /// Reference to the NPC. Not always available.
  let id: FormReference?

  /// Outfit filename (without extension) that this NPC uses.
  var outfit: String?

  /// Where the outfit came from.
  /// For example, the INI filename or mod name.
  var outfitSource: String? = nil

  /// Any outfit collisions for this NPC.
  /// Each tuple contains (outfit name, outfit source)
  /// for an outfit that conflicts with the assigned one.
  var outfitCollisions: [OutfitCollision]? = nil

  /// Whether this NPC is blacklisted from underwear assignment.
  let blacklistForUnderwear: Bool?

  init(
    id: FormReference? = nil,
    outfit: String? = nil,
    outfitSource: String? = nil,
    outfitCollisions: [OutfitCollision]? = nil,
    blacklistForUnderwear: Bool? = nil
  ) {
    self.id = id
    self.outfit = outfit
    self.outfitSource = outfitSource
    self.outfitCollisions = outfitCollisions
    self.blacklistForUnderwear = blacklistForUnderwear
  }
}

struct OutfitCollision: Codable, Equatable, Hashable {
  let outfit: String
  let source: String
}
