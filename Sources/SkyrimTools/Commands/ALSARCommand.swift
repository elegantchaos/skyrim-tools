// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/11/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

// TODO: Split the config file into settings and data files? The user should only need to change the settings.

struct AlsarCommand: LoggableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "alsar",
      abstract: "Generate ALSAR data."
    )
  }

  @Flag() var verbose: Bool = false
  @Flag() var pull: Bool = false
  @Option(help: "Path to a the alsar.json config file.") var configPath: String?
  @Option(help: "Path to the ini files.") var iniPath: String?

  mutating func run() throws {
    guard let configURL = configPath?.relativeURL else {
      log("No config path provided; skipping.")
      return
    }

    guard let iniURL = iniPath?.relativeURL else {
      log("No ini path provided; skipping.")
      return
    }

    if pull {
      try pullSettings(configURL: configURL, iniURL: iniURL)
    } else {
      try generateSettings(configURL: configURL, iniURL: iniURL)
    }
    log("Done.")
  }

  /// Generate ALSAR settings from a config file.
  func generateSettings(configURL: URL, iniURL: URL) throws {
    log("Generating ALSAR settings...")

    let decoder = JSONDecoder()
    let configFileURL = configURL.appendingPathExtension("config.json")
    let config = try decoder.decode(
      ARMOConfig.self, from: try Data(contentsOf: configFileURL))

    let sourceFileURL = configURL.appendingPathExtension("source.json")
    let source = try decoder.decode(
      ARMOSource.self, from: try Data(contentsOf: sourceFileURL))

    let armoEntries = sortedARMOEntries(config: config, source: source)
    try writeARMOSettings(entries: armoEntries, iniURL: iniURL)

    let armaEntries = sortedARMAEntries(config: config, source: source)
    try writeARMASettings(entries: armaEntries, iniURL: iniURL)
  }

  /// Extract initial settings from the ALSAR ini files and write out a config file.
  func pullSettings(configURL: URL, iniURL: URL) throws {
    log("Extracting ALSAR settings...")
    var armos = try extractARMOData(iniURL: iniURL)
    let armas = try extractARMAData(iniURL: iniURL)

    var modes: [String: ARMOMode] = [:]
    var settings: [String: ARMAOptions] = [:]

    for (name, armo) in armos {
      if let mode = armo.mode {
        modes[name] = mode
      } else {
        log("Warning: Missing mode for ARMO \(name)")
      }

      if let pair = armas[armo.arma] {
        if let options = pair.options {
          settings[armo.arma] = options
        } else {
          log("Warning: Missing options for ARMA \(armo.arma) referenced by ARMO \(name)")
        }

        armo.category = pair.category
      } else {
        log("Warning: No ARMA found for \(armo.arma) referenced by ARMO \(name)")
      }

      armos[name] = armo
    }

    for (_, pair) in armas {
      pair.options = nil
    }

    let config = ARMOConfig(
      modes: modes,
      options: settings,
    )

    let source = ARMOSource(armour: armos, mapping: armas)

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(config).write(to: configURL.appendingPathExtension("config.json"))
    try encoder.encode(source).write(to: configURL.appendingPathExtension("source.json"))
    log("Wrote ALSAR config and source to \(configURL.path)")
  }

  /// Get sorted list of enabled armour entries.
  func sortedARMOEntries(config: ARMOConfig, source: ARMOSource) -> [(String, ARMOMode, ARMOEntry)]
  {
    return config.modes.compactMap { name, mode in
      if let armour = source.armour[name] {
        return (name, mode, armour)
      } else {
        log("Warning: No ARMA mapping found for armour piece \(name) in config modes.")
        return nil
      }
    }.sorted { $0.2.formID < $1.2.formID }
  }

  typealias SortedARMAEntry = (String, ARMAOptions, ARMAEntry, String, String)

  /// Sorted list of ARMA entries for all armour pieces.
  /// Entries are sorted by mode (L before W) then by ARMA name.
  /// (this is approximately the order in the original ALSAR ini file)
  func sortedARMAEntries(config: ARMOConfig, source: ARMOSource) -> [SortedARMAEntry] {
    var entries: [SortedARMAEntry] = []

    for (name, pair) in source.mapping {
      let category = pair.category
      let options =
        config.options[name]
        ?? ((category == .other)
          ? ARMAOptions(skirt: false, panty: false, bra: false, greaves: true) : .all)

      if let loose = pair.loose {
        let looseEntry = ARMAEntry(
          category: category,
          formID: loose.formID,
          options: options,
          priority: pair.priority,
          dlc: pair.dlc,
          editorID: loose.editorID
        )
        entries.append((name, options, looseEntry, "L", name))
      }

      if let fitted = pair.fitted {
        let fittedEntry = ARMAEntry(
          category: category,
          formID: fitted.formID,
          options: options,
          priority: pair.priority,
          dlc: pair.dlc,
          editorID: fitted.editorID
        )
        entries.append((name, options, fittedEntry, "W", name))
      }

    }

    return entries.sorted { (e1: SortedARMAEntry, e2: SortedARMAEntry) in
      let m1 = e1.3
      let m2 = e2.3
      return (m1 == m2) ? (e1.0 < e2.0) : (m1 < m2)
    }
  }

  /// Write out the ARMO settings file.
  func writeARMOSettings(entries: [(String, ARMOMode, ARMOEntry)], iniURL: URL) throws {
    var armo = "ArmoFormID\tWorL\tDLC\tARMA_NAME\tARMO_NAME\n"

    for (name, mode, armour) in entries {
      if mode == .off {
        armo += "# "
      }
      let hexForm = String(format: "%08X", armour.formID)
      armo += "\(hexForm)\t\(mode.configChar)\t\(armour.dlc)\t\(armour.arma)\t\(name)\n"
    }

    let armoURL = iniURL.appending(path: "zzLSARSetting_ARMO.ini")
    try armo.write(to: armoURL)
  }

  /// Write out the ARMA settings file.
  func writeARMASettings(entries: [SortedARMAEntry], iniURL: URL) throws {
    var arma = """
      #ARMA_CONFIG										
      # NAME and WorL: key of ARMA ( like "L" + "ArchmageRobesAA" )										
      # formID: ARMA's formID										
      # armo_type: C/L/H/O = Clothes/LightArmor/HeavyArmor/Other										
      # WorL: wellfitted or Loose										
      # skirt, panty, bra, greave: active/deactive swith. ( greave on/off function is disable from 2018/05/06 )										
      # priority: priority in ARMA										
      # dls_type: 0/1/3 = skyrim.esm/dawnguard.esm/dragonborn.esm										
      #src     		armo	Wor	ski	pan	bra	gre	pri	dlc	
      #NAME	formID    	type	L	rt	ty		ave	ori	Type	EDITORID

      """

    arma += try filteredARMAChunk(entries: entries, filter: .cloth, filterName: "CLOTH")
    arma += try filteredARMAChunk(entries: entries, filter: .light, filterName: "LIGHT_ARMOR")
    arma += try filteredARMAChunk(entries: entries, filter: .heavy, filterName: "HEAVY_ARMOR")
    arma += try filteredARMAChunk(entries: entries, filter: .other, filterName: "HELMET")

    arma += "# END OF LINE\n"

    let armaURL = iniURL.appending(path: "zzLSARSetting_ARMA.ini")
    try arma.write(to: armaURL)
  }

  /// Get a chunk of ARMA entries filtered by category.
  func filteredARMAChunk(
    entries: [SortedARMAEntry], filter: ARMACategory, filterName: String
  ) throws -> String {
    var arma = ""
    var done = Set<String>()

    arma +=
      "#DO_NOT_EDIT_THIS_LINE:\(filterName)-----------------------------------------------\t\t\t\t\t\t\t\t\t\t\n"

    for (name, options, entry, mode, _) in entries {
      let variant = "\(mode)\(name)"
      if !done.contains(variant) {
        done.insert(variant)
        if entry.category == filter {
          arma += "\(name)\t"
          arma += "\(String(format: "%08X", entry.formID))\t"
          arma += "\(entry.category.letterCode)\t"
          arma += "\(mode)\t"
          arma += options.skirt ? "1\t" : "0\t"
          arma += options.panty ? "1\t" : "0\t"
          arma += options.bra ? "1\t" : "0\t"
          arma += options.greaves ? "1\t" : "0\t"
          arma += "\(entry.priority)\t"
          arma += "\(entry.dlc)\t"
          arma += "\(entry.editorID)\n"
        }
      }
    }

    return arma
  }

  func extractARMOData(iniURL: URL) throws -> [String: ARMOEntry] {
    let armoURL = iniURL.appending(path: "zzLSARSetting_ARMO.ini")
    let lines = try String(contentsOf: armoURL, encoding: .utf8)
      .components(separatedBy: .newlines)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

    var armos: [String: ARMOEntry] = [:]

    for line in lines {
      let fields = line.split(separator: "\t")
      if fields.count >= 5 {
        let name = String(fields[4])
        if name != "ARMO_NAME" {  // skip header
          let entry = ARMOEntry(
            formID: Int(fields[0], radix: 16) ?? 0,
            mode: ARMOMode.fromCode(String(fields[1])),
            dlc: Int(fields[2]) ?? 0,
            arma: String(fields[3]),
          )
          armos[name] = entry
        }
      }
    }

    return armos
  }

  func extractARMAData(iniURL: URL) throws -> [String: ARMAPair] {
    let armaURL = iniURL.appending(path: "zzLSARSetting_ARMA.ini")
    let lines = try String(contentsOf: armaURL, encoding: .utf8)
      .components(separatedBy: .newlines)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

    var looseArmas: [String: ARMAEntry] = [:]
    var fittedArmas: [String: ARMAEntry] = [:]

    for line in lines {
      if line.isEmpty || line.starts(with: "#") {
        continue
      }

      let fields = line.split(separator: "\t")
      let category = ARMACategory.fromCode(String(fields[2]))
      if fields.count == 11 {
        let name = String(fields[0])
        let options = ARMAOptions(
          skirt: fields[4] == "1",
          panty: fields[5] == "1",
          bra: fields[6] == "1",
          greaves: fields[7] == "1"
        )
        let entry = ARMAEntry(
          category: category,
          formID: Int(fields[1], radix: 16) ?? 0,
          options: options,
          priority: Int(fields[8]) ?? 0,
          dlc: Int(fields[9]) ?? 0,
          editorID: String(fields[10])
        )

        let isLoose = fields[3] == "L"
        if isLoose {
          looseArmas[name] = entry
        } else {
          fittedArmas[name] = entry
        }
      }

    }

    let looseKeys = Set(looseArmas.keys)
    let fittedKeys = Set(fittedArmas.keys)
    let combinedKeys = looseKeys.union(fittedKeys)
    var pairs: [String: ARMAPair] = [:]
    for key in combinedKeys {
      let loose = looseArmas[key]
      let fitted = fittedArmas[key]
      checkForMismatches(loose: loose, fitted: fitted, key: key)

      if let common = loose ?? fitted {
        let looseCompact = loose.map {
          ARMACompact(formID: $0.formID, editorID: $0.editorID)
        }

        let fittedCompact = fitted.map {
          ARMACompact(formID: $0.formID, editorID: $0.editorID)
        }

        pairs[key] = ARMAPair(
          category: common.category,
          dlc: common.dlc,
          priority: common.priority,
          loose: looseCompact,
          fitted: fittedCompact,
          options: common.options
        )
      }
    }

    return pairs
  }

  func checkForMismatches(
    loose: ARMAEntry?, fitted: ARMAEntry?, key: String
  ) {
    if let loose, let fitted {
      if loose.dlc != fitted.dlc {
        log("Warning: DLC mismatch between loose and fitted ARMA for \(key)")
      }
      if loose.category != fitted.category {
        log("Warning: Category mismatch between loose and fitted ARMA for \(key)")
      }
      if loose.priority != fitted.priority {
        log("Warning: Priority mismatch between loose and fitted ARMA for \(key)")
      }
      if loose.options.skirt != fitted.options.skirt
        || loose.options.panty != fitted.options.panty || loose.options.bra != fitted.options.bra
        || loose.options.greaves != fitted.options.greaves
      {
        log("Warning: Options mismatch between loose and fitted ARMA for \(key)")
      }
    } else if loose != nil {
      log("Warning: Only loose ARMA present for \(key)")
    } else if fitted != nil {
      log("Warning: Only fitted ARMA present for \(key)")
    }
  }

}

/// Configuration file.
struct ARMOConfig: Codable {
  /// Modes for each armour piece.
  let modes: [String: ARMOMode]

  /// Options for each armour piece.
  let options: [String: ARMAOptions]
}

/// Source data for armour pieces.
struct ARMOSource: Codable {
  let armour: [String: ARMOEntry]
  let mapping: [String: ARMAPair]

}

/// Entry for an armour piece, taken from the zzLSARSetting_ARMO.ini file.
class ARMOEntry: Codable {
  internal init(
    formID: Int, mode: ARMOMode, dlc: Int, arma: String
  ) {
    self.formID = formID
    self.mode = mode
    self.dlc = dlc
    self.arma = arma
  }

  let formID: Int
  let mode: ARMOMode?
  let dlc: Int
  let arma: String
  var category: ARMACategory?
}

/// Category of armour.
enum ARMACategory: String, Codable {
  case cloth
  case light
  case heavy
  case other

  static func fromCode(_ code: String) -> Self {
    switch code {
    case "C":
      return .cloth
    case "L":
      return .light
    case "H":
      return .heavy
    default:
      return .other
    }
  }

  var letterCode: String {
    switch self {
    case .cloth:
      return "C"
    case .light:
      return "L"
    case .heavy:
      return "H"
    case .other:
      return "O"
    }
  }
}

/// Pair of loose and fitted ARMA entries.
class ARMAPair: Codable {
  internal init(
    category: ARMACategory, dlc: Int, priority: Int, loose: ARMACompact?, fitted: ARMACompact?,
    options: ARMAOptions? = nil
  ) {
    self.category = category
    self.dlc = dlc
    self.priority = priority
    self.loose = loose
    self.fitted = fitted
    self.options = options
  }

  let category: ARMACategory
  let dlc: Int
  let priority: Int
  let loose: ARMACompact?
  let fitted: ARMACompact?
  var options: ARMAOptions?
}

/// Mode for an armour piece.
/// - off: No ALSAR applied.
/// - loose: Loose fit.
/// - fitted: Well-fitted fit.
enum ARMOMode: String, Codable {
  /// No ALSAR applied.
  case off

  /// Loose fit.
  case loose

  /// Well-fitted fit.
  case fitted

  static func fromCode(_ code: String) -> Self {
    switch code {
    case "L":
      return .loose
    case "W":
      return .fitted
    default:
      return .off
    }
  }

  var configChar: String {
    switch self {
    case .off:
      return "O"
    case .loose:
      return "L"
    case .fitted:
      return "W"
    }
  }
}

/// Entry for an ARMA record, taken from the zzLSARSetting_ARMA.ini file.
struct ARMAEntry: Codable {
  let category: ARMACategory
  let formID: Int
  let options: ARMAOptions
  let priority: Int
  let dlc: Int
  let editorID: String
}

/// Compact representation of an ARMA record.
struct ARMACompact: Codable {
  let formID: Int
  let editorID: String
}

/// Options for an ARMA record.
struct ARMAOptions: Codable {
  let skirt: Bool
  let panty: Bool
  let bra: Bool
  let greaves: Bool

  init(skirt: Bool = true, panty: Bool = true, bra: Bool = true, greaves: Bool = true) {
    self.skirt = skirt
    self.panty = panty
    self.bra = bra
    self.greaves = greaves
  }

  static let none = ARMAOptions(skirt: false, panty: false, bra: false, greaves: false)
  static let all = ARMAOptions(skirt: true, panty: true, bra: true, greaves: true)
}
