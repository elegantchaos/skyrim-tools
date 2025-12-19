// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Model for a sleep set JSON file used by OBody.
/// Each file declares a list of armour form references and metadata consumed by the mod.
struct SleepSet: Codable {
  /// Container for the armour references included in this set.
  struct Items: Codable {
    /// Form references in `0xFORMID|Mod.esp` format.
    var items: [String]
  }

  /// Metadata block expected by the sleep set schema.
  struct Metadata: Codable {
    /// Mode identifier consumed by the mod.
    var itemmode: Int

    /// Schema version used by the mod.
    let version: Int
  }

  /// Armour references for this set.
  var formList: Items

  /// Metadata for the set.
  var int: Metadata

  /// Empty template to fall back on if we can't find the default sleep set.
  static let empty = SleepSet(
    formList: Items(items: []),
    int: Metadata(itemmode: 0, version: 110)
  )

  /// Modes for sleep set item selection.
  enum ItemMode: Int {
    case any = 0  // use any one item
    case all = 1  // use all items
    case color = 2  // use color matching
    case body = 3  // use all items but one body (slot32)

  }

  /// The item mode for this sleep set.
  var mode: ItemMode {
    get { ItemMode(rawValue: int.itemmode) ?? .any }
    set { int.itemmode = newValue.rawValue }
  }
}
