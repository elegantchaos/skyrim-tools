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
  case armor
  case light
  case heavy
  case mask
}

struct ALSARInfo: Codable, Equatable {
  internal init(
    mode: ARMOMode,
    arma: String,
    pair: ARMAPair?,
    options: ARMAOptions? = nil
  ) {
    let defaults = ARMAOptions.default

    self.mode = mode
    self.priority = pair?.priority
    self.arma = arma
    self.alias = nil
    self.loose = pair?.loose.map { FormReference($0) }
    self.fitted = pair?.fitted.map { FormReference($0) }
    self.skirt = options?.skirt == defaults.skirt ? nil : !defaults.skirt
    self.panty = options?.panty == defaults.panty ? nil : !defaults.panty
    self.greaves = options?.greaves == defaults.greaves ? nil : !defaults.greaves
    self.bra = options?.bra == defaults.bra ? nil : !defaults.bra
    self.skipARMO = nil
  }

  let mode: ARMOMode
  let priority: Int?
  let arma: String
  let alias: String?
  let loose: FormReference?
  let fitted: FormReference?
  let skirt: Bool?
  let panty: Bool?
  let bra: Bool?
  let greaves: Bool?
  let skipARMO: Bool?

  var options: ARMAOptions {
    ARMAOptions(
      skirt: skirt,
      panty: panty,
      bra: bra,
      greaves: greaves
    )
  }
}
