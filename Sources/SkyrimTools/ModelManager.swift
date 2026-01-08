// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Manages loading and storing Skyrim mod configuration data.
///
/// This class handles the persistence of mod-related data across multiple record types,
/// maintaining in-memory indexes that can be queried and modified, then written back to disk.
@Observable
class ModelManager {
  let dataURL: URL
  let modsURL: URL
  let outfitsURL: URL
  let peopleURL: URL
  let armorsURL: URL
  let sleepSetsURL: URL

  private(set) var mods: [String: ModRecord] = [:]
  private(set) var outfits: [String: FormReference] = [:]
  private(set) var people: [String: PersonRecord] = [:]
  private(set) var armors: [String: ArmorRecord] = [:]
  private(set) var sleepSets: [String: SleepSet] = [:]

  private var modifiedMods: Set<String> = []
  private var modifiedOutfits: Set<String> = []
  private var modifiedPeople: Set<String> = []
  private var modifiedArmors: Set<String> = []

  private(set) var editorIDToNameMap: [String: String] = [:]

  private let decoder = JSONDecoder()
  private let encoder: JSONEncoder

  /// Initialize the manager with a data folder URL.
  ///
  /// - Parameter dataURL: The URL to the root data folder containing subdirectories:
  ///   "Mods", "Outfits", "People", and "Armors"
  /// - Throws: If the subdirectories cannot be created or files cannot be read.
  init(dataURL: URL) throws {
    self.dataURL = dataURL
    self.modsURL = dataURL.appending(path: "Mods")
    self.outfitsURL = dataURL.appending(path: "Outfits")
    self.peopleURL = dataURL.appending(path: "People")
    self.armorsURL = dataURL.appending(path: "Armors")
    self.sleepSetsURL = dataURL.appending(path: "SleepSets")

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    self.encoder = encoder

    let fm = FileManager.default
    try fm.createDirectory(at: modsURL, withIntermediateDirectories: true)
    try fm.createDirectory(at: outfitsURL, withIntermediateDirectories: true)
    try fm.createDirectory(at: peopleURL, withIntermediateDirectories: true)
    try fm.createDirectory(at: armorsURL, withIntermediateDirectories: true)
    try fm.createDirectory(at: sleepSetsURL, withIntermediateDirectories: true)

    try loadIndexes()

    for (name, armor) in armors {
      if let editorID = armor.id.editorID {
        if let existing = editorIDToNameMap[editorID], existing != name {
          print(
            "Warning: Duplicate editorID \(editorID) with differing names: \(existing) vs \(name)")
        }
        editorIDToNameMap[editorID] = name
      }
    }
  }

  /// Load indexes from disk.
  private func loadIndexes() throws {
    mods = try loadIndex(from: modsURL, as: ModRecord.self)
    outfits = try loadIndex(from: outfitsURL, as: FormReference.self)
    people = try loadIndex(from: peopleURL, as: PersonRecord.self)
    armors = try loadIndex(from: armorsURL, as: ArmorRecord.self)
    sleepSets = try loadIndex(from: sleepSetsURL, as: SleepSet.self)
  }

  /// Load a specific index from a directory.
  private func loadIndex<T: Decodable>(from url: URL, as type: T.Type) throws -> [String: T] {
    var index: [String: T] = [:]
    let fm = FileManager.default
    let files = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)

    for fileURL in files {
      guard fileURL.pathExtension.lowercased() == "json" else { continue }
      let rawBase = fileURL.deletingPathExtension().lastPathComponent
      let key = rawBase.unescapedKey
      do {
        let data = try Data(contentsOf: fileURL)
        let record = try decoder.decode(T.self, from: data)
        index[key] = record
      } catch {
        print("Warning: Failed to load \(fileURL.lastPathComponent): \(error)")
      }
    }

    return index
  }

  /// Retrieve a mod record if it exists.
  /// - Parameter key: The mod name (filename without extension).
  /// - Returns: The existing mod record or `nil` if not present.
  func mod(_ key: String) -> ModRecord? {
    mods[key]
  }

  /// Retrieve a mod record, creating one with the supplied factory if missing.
  /// - Parameters:
  ///   - key: The mod name (filename without extension).
  ///   - default: Factory closure returning a default record when one doesn't exist.
  /// - Returns: The existing or newly created mod record.
  func mod(_ key: String, default factory: () -> ModRecord) -> ModRecord {
    if let record = mods[key] { return record }
    let record = factory()
    mods[key] = record
    modifiedMods.insert(key)
    return record
  }

  /// Update a mod record with a new value.
  /// Marks the record as modified only if it differs from the existing one.
  ///
  /// - Parameters:
  ///   - key: The mod name (filename without extension).
  ///   - newValue: The new mod record value.
  func updateMod(_ key: String, _ newValue: ModRecord) {
    if mods[key] != newValue {
      mods[key] = newValue
      modifiedMods.insert(key)
    }
  }

  /// Retrieve an outfit record if it exists.
  /// - Parameter key: The outfit name (filename without extension).
  /// - Returns: The existing outfit record or `nil` if not present.
  func outfit(_ key: String) -> FormReference? {
    outfits[key]
  }

  /// Retrieve an outfit record, creating one with the supplied factory if missing.
  /// - Parameters:
  ///   - key: The outfit name (filename without extension).
  ///   - default: Factory closure returning a default record when one doesn't exist.
  /// - Returns: The existing or newly created outfit record.
  func outfit(_ key: String, default factory: () -> FormReference) -> FormReference {
    if let record = outfits[key] { return record }
    let record = factory()
    outfits[key] = record
    modifiedOutfits.insert(key)
    return record
  }

  /// Update an outfit record with a new value.
  /// Marks the record as modified only if it differs from the existing one.
  ///
  /// - Parameters:
  ///   - key: The outfit name (filename without extension).
  ///   - newValue: The new outfit record value.
  func updateOutfit(_ key: String, _ newValue: FormReference) {
    if outfits[key] != newValue {
      outfits[key] = newValue
      modifiedOutfits.insert(key)
    }
  }

  /// Retrieve a person record if it exists.
  /// - Parameter key: The NPC name (filename without extension).
  /// - Returns: The existing person record or `nil` if not present.
  func person(_ key: String) -> PersonRecord? {
    people[key]
  }

  /// Retrieve a person record, creating one with the supplied factory if missing.
  /// - Parameters:
  ///   - key: The NPC name (filename without extension).
  ///   - default: Factory closure returning a default record when one doesn't exist.
  /// - Returns: The existing or newly created person record.
  func person(_ key: String, default factory: () -> PersonRecord) -> PersonRecord {
    if let record = people[key] { return record }
    let record = factory()
    people[key] = record
    modifiedPeople.insert(key)
    return record
  }

  /// Update a person record with a new value.
  /// Marks the record as modified only if it differs from the existing one.
  ///
  /// - Parameters:
  ///   - key: The NPC name (filename without extension).
  ///   - newValue: The new person record value.
  func updatePerson(_ key: String, _ newValue: PersonRecord) {
    if people[key] != newValue {
      people[key] = newValue
      modifiedPeople.insert(key)
    }
  }

  /// Retrieve an armor record if it exists.
  /// - Parameter key: The armor name (filename without extension).
  /// - Returns: The existing armor record or `nil` if not present.
  func armor(_ key: String) -> ArmorRecord? {
    armors[key]
  }

  func armor(editorID: String) -> ArmorRecord? {
    guard let name = editorIDToNameMap[editorID] else { return nil }
    return armor(name)
  }

  /// Retrieve an armor record, creating one with the supplied factory if missing.
  /// - Parameters:
  ///   - key: The armor name (filename without extension).
  ///   - default: Factory closure returning a default record when one doesn't exist.
  /// - Returns: The existing or newly created armor record.
  func armor(_ key: String, default factory: () -> ArmorRecord) -> ArmorRecord {
    if let record = armors[key] { return record }
    let record = factory()
    armors[key] = record
    modifiedArmors.insert(key)
    return record
  }

  /// Retrieve an armor record, creating one with the supplied factory if missing.
  /// - Parameters:
  ///   - editorID: The armor editorID.
  ///   - default: Factory closure returning a default record when one doesn't exist.
  /// - Returns: The existing or newly created armor record.
  func armor(editorID: String, default factory: (String) -> ArmorRecord) -> ArmorRecord {
    if let record = armor(editorID: editorID) { return record }
    let key =
      editorID
      .replacingOccurrences(of: "_", with: " ")
      .trimmingCharacters(in: .whitespaces)

    let record = factory(key)
    armors[key] = record
    editorIDToNameMap[editorID] = key
    modifiedArmors.insert(key)
    return record
  }

  /// Update an armor record with a new value.
  /// Marks the record as modified only if it differs from the existing one.
  ///
  /// - Parameters:
  ///   - key: The armor name (filename without extension).
  ///   - newValue: The new armor record value.
  func updateArmor(_ key: String, _ newValue: ArmorRecord) {
    if armors[key] != newValue {
      armors[key] = newValue
      modifiedArmors.insert(key)
    }
  }

  func updateArmor(editorID: String, _ newValue: ArmorRecord) {
    if let key = editorIDToNameMap[editorID] {
      if armors[key] != newValue {
        armors[key] = newValue
        modifiedArmors.insert(key)
      }
    } else {
      print("Warning: Attempted to update armor with unknown editorID \(editorID)")
    }
  }

  /// Retrieve a sleep set template if it exists.
  /// - Parameter key: The sleep set name (filename without extension).
  /// - Returns: The existing template or `nil` if not present.
  func sleepSet(_ key: String) -> SleepSet? {
    sleepSets[key]
  }

  /// Retrieve a sleep set template, falling back to the supplied default when missing.
  /// The template is not persisted back to disk; sleep sets are treated as read-only templates.
  /// - Parameters:
  ///   - key: The sleep set name (filename without extension).
  ///   - default: Factory returning a template when one doesn't exist.
  /// - Returns: The existing or default template.
  func sleepSet(_ key: String, default factory: () -> SleepSet) -> SleepSet {
    sleepSets[key] ?? factory()
  }

  /// Write all modified records back to disk.
  ///
  /// - Throws: If any write operation fails.
  func save() throws {
    try saveIndex(mods, to: modsURL, modified: modifiedMods)
    try saveIndex(outfits, to: outfitsURL, modified: modifiedOutfits)
    try saveIndex(people, to: peopleURL, modified: modifiedPeople)
    try saveIndex(armors, to: armorsURL, modified: modifiedArmors)

    modifiedMods.removeAll()
    modifiedOutfits.removeAll()
    modifiedPeople.removeAll()
    modifiedArmors.removeAll()
  }

  /// Save modified records to a directory.
  private func saveIndex<T: Encodable>(
    _ index: [String: T], to url: URL, modified: Set<String>
  ) throws {
    for key in modified {
      guard let record = index[key] else { continue }
      let base = key.keyEscapingSlashes
      let fileURL = url.appending(path: "\(base).json")
      let newData = try encoder.encode(record)

      // Check if file exists and has identical content
      if FileManager.default.fileExists(atPath: fileURL.path) {
        if let existingData = try? Data(contentsOf: fileURL), existingData == newData {
          continue  // Skip writing if content is identical
        }
      }

      do {
        try newData.write(to: fileURL)
      } catch {
        print("Warning: Failed to save \(fileURL.lastPathComponent): \(error)")
      }
    }
  }
}

// Migration of legacy mod armour formats has been removed.

extension String {
  /// Escape a record key to remove slashes for use as a filename component.
  var keyEscapingSlashes: String {
    var allowed = CharacterSet.urlPathAllowed
    allowed.formUnion(CharacterSet.punctuationCharacters)
    allowed.remove(charactersIn: "/")
    allowed.insert(" ")
    return self.addingPercentEncoding(withAllowedCharacters: allowed) ?? self
  }

  /// Unescape a filename component (which might contain escaped slashes) back into the original key.
  var unescapedKey: String {
    self.removingPercentEncoding ?? self
  }

}
