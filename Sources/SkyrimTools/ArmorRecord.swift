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
}

struct ALSARInfo: Codable, Equatable {
  internal init(
    mode: ARMOMode,
    arma: String,
    pair: ARMAPair?,
    options: ARMAOptions? = nil
  ) {
    let def = ARMAOptions.default

    self.mode = mode
    self.priority = pair?.priority
    self.arma = arma
    self.loose = pair?.loose.map { FormReference($0) }
    self.fitted = pair?.fitted.map { FormReference($0) }
    self.skirt = options?.skirt == def.skirt ? nil : !def.skirt
    self.panty = options?.panty == def.panty ? nil : !def.panty
    self.greaves = options?.greaves == def.greaves ? nil : !def.greaves
    self.bra = options?.bra == def.bra ? nil : !def.bra
  }

  let mode: ARMOMode
  let priority: Int?
  let arma: String
  let loose: FormReference?
  let fitted: FormReference?
  let skirt: Bool?
  let panty: Bool?
  let bra: Bool?
  let greaves: Bool?

  var skirtInt: Int {
    let value = skirt ?? ARMAOptions.default.skirt
    return value ? 1 : 0
  }

  var pantyInt: Int {
    let value = panty ?? ARMAOptions.default.panty
    return value ? 1 : 0
  }

  var braInt: Int {
    let value = bra ?? ARMAOptions.default.bra
    return value ? 1 : 0
  }

  var greavesInt: Int {
    let value = greaves ?? ARMAOptions.default.greaves
    return value ? 1 : 0
  }
}
