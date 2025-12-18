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

  private(set) var mods: [String: ModRecord] = [:]
  private(set) var outfits: [String: FormReference] = [:]
  private(set) var people: [String: PersonRecord] = [:]
  private(set) var armors: [String: ArmorRecord] = [:]

  private var modifiedMods: Set<String> = []
  private var modifiedOutfits: Set<String> = []
  private var modifiedPeople: Set<String> = []
  private var modifiedArmors: Set<String> = []

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

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    self.encoder = encoder

    let fm = FileManager.default
    try fm.createDirectory(at: modsURL, withIntermediateDirectories: true)
    try fm.createDirectory(at: outfitsURL, withIntermediateDirectories: true)
    try fm.createDirectory(at: peopleURL, withIntermediateDirectories: true)
    try fm.createDirectory(at: armorsURL, withIntermediateDirectories: true)

    try loadIndexes()
  }

  /// Load indexes from disk.
  private func loadIndexes() throws {
    mods = try loadIndex(from: modsURL, as: ModRecord.self)
    outfits = try loadIndex(from: outfitsURL, as: FormReference.self)
    people = try loadIndex(from: peopleURL, as: PersonRecord.self)
    armors = try loadIndex(from: armorsURL, as: ArmorRecord.self)
  }

  /// Load a specific index from a directory.
  private func loadIndex<T: Decodable>(from url: URL, as type: T.Type) throws -> [String: T] {
    var index: [String: T] = [:]
    let fm = FileManager.default
    let files = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)

    for fileURL in files {
      guard fileURL.pathExtension.lowercased() == "json" else { continue }
      let key = fileURL.deletingPathExtension().lastPathComponent
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

  /// Retrieve a mod record, optionally creating one if it doesn't exist.
  ///
  /// - Parameters:
  ///   - key: The mod name (filename without extension).
  ///   - create: If `true`, creates a new default record if one doesn't exist.
  /// - Returns: The mod record, or `nil` if not found and `create` is `false`.
  func mod(_ key: String, _ create: Bool = true) -> ModRecord? {
    if let record = mods[key] {
      return record
    }
    if create {
      let record = ModRecord()
      mods[key] = record
      modifiedMods.insert(key)
      return record
    }
    return nil
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

  /// Retrieve an outfit record, optionally creating one if it doesn't exist.
  ///
  /// - Parameters:
  ///   - key: The outfit name (filename without extension).
  ///   - create: If `true`, creates a new default record if one doesn't exist.
  /// - Returns: The outfit record, or `nil` if not found and `create` is `false`.
  func outfit(_ key: String, _ create: Bool = true) -> FormReference? {
    if let record = outfits[key] {
      return record
    }
    if create {
      // Create a minimal default outfit record
      let record = FormReference(
        formID: "0x0", file: key + ".esp", name: nil, description: nil)
      outfits[key] = record
      modifiedOutfits.insert(key)
      return record
    }
    return nil
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

  /// Retrieve a person record, optionally creating one if it doesn't exist.
  ///
  /// - Parameters:
  ///   - key: The NPC name (filename without extension).
  ///   - create: If `true`, creates a new default record if one doesn't exist.
  /// - Returns: The person record, or `nil` if not found and `create` is `false`.
  func person(_ key: String, _ create: Bool = true) -> PersonRecord? {
    if let record = people[key] {
      return record
    }
    if create {
      let record = PersonRecord(outfit: nil)
      people[key] = record
      modifiedPeople.insert(key)
      return record
    }
    return nil
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

  /// Retrieve an armor record, optionally creating one if it doesn't exist.
  ///
  /// - Parameters:
  ///   - key: The armor name (filename without extension).
  ///   - create: If `true`, creates a new default record if one doesn't exist.
  /// - Returns: The armor record, or `nil` if not found and `create` is `false`.
  func armor(_ key: String, _ create: Bool = true) -> ArmorRecord? {
    if let record = armors[key] {
      return record
    }
    if create {
      let record = ArmorRecord(formID: nil, editorID: nil, name: nil)
      armors[key] = record
      modifiedArmors.insert(key)
      return record
    }
    return nil
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
      let fileURL = url.appending(path: "\(key).json")
      let newData = try encoder.encode(record)

      // Check if file exists and has identical content
      if FileManager.default.fileExists(atPath: fileURL.path) {
        if let existingData = try? Data(contentsOf: fileURL), existingData == newData {
          continue  // Skip writing if content is identical
        }
      }

      try newData.write(to: fileURL)
    }
  }
}
