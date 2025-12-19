// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A record for an armor item.
struct ArmorRecord: Codable, Equatable {
  let id: FormReference
  let useAsUnderwear: Bool?
  var sleepSets: [String]?

  init(id: FormReference, useAsUnderwear: Bool? = nil, sleepSets: [String]? = nil) {
    self.id = id
    self.useAsUnderwear = useAsUnderwear
    self.sleepSets = sleepSets
  }
}
