// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/01/2026.
//  All code (c) 2026 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

extension AlsarCommand {

  /// Extract initial settings from the ALSAR ini files and add ArmorRecords
  /// to the model for each armour piece.
  func pullSettings(iniURL: URL, model: ModelManager) throws {
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
        settings[armo.arma] = .default
      }

      armos[name] = armo
    }

    for (name, alsarArmor) in armos {
      var armor = model.armor(name, default: { makeArmorRecord(name: name, for: alsarArmor) })
      let keywords = armor.keywords ?? Set<Keyword>()
      armor.keywords = keywords.union(alsarArmor.category?.alsarKeywords ?? [])
      let armaName = alsarArmor.arma
      if let mode = modes[name] {
        let alsarArma = armas[armaName]
        let options = settings[armaName]
        let alsarInfo = ALSARInfo(
          mode: mode,
          arma: armaName,
          pair: alsarArma,
          options: options
        )
        armor.alsar = alsarInfo
      }

      model.updateArmor(name, armor)
    }

    try model.save()
  }

  /// Extract ARMO data from the ini file.
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
        var id = fields[0]
        var mode = String(fields[1])
        if id.hasPrefix("#") {
          id = id.dropFirst()
          while id.hasPrefix(" ") {
            id = id.dropFirst()
          }
          mode = "O"  // off
        }
        if name != "ARMO_NAME" {  // skip header
          let entry = ARMOEntry(
            formID: (UInt(id, radix: 16) ?? 0) & 0x00FF_FFFF,
            mode: ARMOMode.fromIni(mode),
            dlc: Int(fields[2]) ?? 0,
            arma: String(fields[3]),
          )
          armos[name] = entry
        }
      }
    }

    return armos
  }

  /// Extract ARMA data from the ini file.
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
      let category = ARMACategory.fromIni(String(fields[2]))
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

        pairs[key] = ARMAPair(
          category: common.category,
          dlc: common.dlc,
          priority: common.priority,
          loose: loose,
          fitted: fitted,
          options: common.options
        )
      }
    }

    return pairs
  }

  /// Check for mismatches between loose and fitted ARMA entries.
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

  /// Create an armor record for the given ARMO entry.
  func makeArmorRecord(name: String, for armor: ARMOEntry) -> ArmorRecord {
    let mod =
      switch armor.dlc {
      case 1: "dawnguard.esm"
      case 3: "dragonborn.esm"
      default: "skyrim.esm"
      }
    let ref = FormReference(
      intFormID: armor.formID,
      editorID: name,
      mod: mod
    )
    return ArmorRecord(id: ref)
  }
}
