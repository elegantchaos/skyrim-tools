// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A record for an armor item.
struct ArmorRecord: Codable, Equatable {
  let id: FormReference
  let useAsUnderwear: Bool?
  var alsar: ALSARInfo?
  var sleepSets: [String]?
  var keywords: Set<Keyword>?

  init(
    id: FormReference, useAsUnderwear: Bool? = nil, sleepSets: [String]? = nil,
    keywords: Set<Keyword>? = nil
  ) {
    self.id = id
    self.useAsUnderwear = useAsUnderwear
    self.sleepSets = sleepSets
    self.keywords = keywords
  }
}

enum Keyword: String, Codable {
  case alsar
  case clothing
  case lightArmor
  case heavyArmor
}

struct ALSARInfo: Codable, Equatable {
  internal init(
    mode: ARMOMode,
    priority: Int,
    loose: ARMACompact?,
    fitted: ARMACompact?,
    options: ARMAOptions? = nil
  ) {
    let def = ARMAOptions.default

    self.mode = mode
    self.priority = priority
    self.loose = loose
    self.fitted = fitted
    self.skirt = options?.skirt == def.skirt ? nil : !def.skirt
    self.panty = options?.panty == def.panty ? nil : !def.panty
    self.greaves = options?.greaves == def.greaves ? nil : !def.greaves
    self.bra = options?.bra == def.bra ? nil : !def.bra
  }

  let mode: ARMOMode
  let priority: Int
  let loose: ARMACompact?
  let fitted: ARMACompact?
  let skirt: Bool?
  let panty: Bool?
  let bra: Bool?
  let greaves: Bool?
}
