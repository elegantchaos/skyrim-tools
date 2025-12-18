// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A mod configuration record capturing OBody/RSV blacklist flags.
struct ModRecord: Codable {
  /// Should we add the mod to the blacklist for OBody?
  let skipOBody: Bool?

  /// Should we add the mod to the blacklist for OBody female?
  let skipOBodyFemale: Bool?

  /// Should we add the mod to the blacklist for OBody male?
  let skipOBodyMale: Bool?

  /// Should we add the mod to the blacklist for RSV?
  let skipRSV: Bool?

  /// Sleep armour records for this mod.
  let armours: [SleepArmourRecord]?

  /// Outfit names for this mod.
  let outfits: [String]?

  /// NPCs defined (or modified?) by this mod.
  let npcs: [String]?

  init(
    skipOBody: Bool? = nil,
    skipOBodyFemale: Bool? = nil,
    skipOBodyMale: Bool? = nil,
    skipRSV: Bool? = nil,
    armours: [SleepArmourRecord]? = nil,
    outfits: [String]? = nil,
    npcs: [String]? = nil
  ) {
    self.skipOBody = skipOBody
    self.skipOBodyFemale = skipOBodyFemale
    self.skipOBodyMale = skipOBodyMale
    self.skipRSV = skipRSV
    self.armours = armours
    self.outfits = outfits
    self.npcs = npcs
  }
}
