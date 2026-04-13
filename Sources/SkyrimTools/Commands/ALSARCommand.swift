// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/11/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

struct AlsarCommand: LoggableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "alsar",
      abstract: "Generate ALSAR data."
    )
  }

  @Flag() var verbose: Bool = false
  @Option(help: "Path to the ini files.") var iniPath: String?
  @Option(
    help:
      "Path to the model data folder containing Mods, Outfits, People, and Armors subdirectories.")
  var modelPath: String?

  mutating func run() throws {
    guard let iniURL = iniPath?.relativeURL else {
      log("No ini path provided; skipping.")
      return
    }

    guard let modelURL = modelPath?.relativeURL else {
      print("No model path specified.")
      return
    }
    let model = try ModelManager(dataURL: modelURL)

    try generateSettings(iniURL: iniURL, model: model)
    log("Done.")
  }

  /// Generate ALSAR settings from a config file.
  func generateSettings(iniURL: URL, model: ModelManager) throws {
    log("Generating ALSAR settings...")

    let armors =
      model.armors
      .filter { ($0.value.alsar != nil) && ($0.value.id.formID != nil) }
      .sorted { $0.value.id.fullIntFormID! < $1.value.id.fullIntFormID! }

    try writeARMOSettings(armors: armors, iniURL: iniURL, model: model)
    try writeARMASettings(armors: armors, iniURL: iniURL, model: model)

    // try model.tempSaveAll()
  }

  /// Write out the ARMO settings file.
  func writeARMOSettings(armors: [(String, ArmorRecord)], iniURL: URL, model: ModelManager) throws {
    var armo = "ArmoFormID\tWorL\tDLC\tARMA_NAME\tARMO_NAME\n"

    for (name, armor) in armors {
      if let alsarInfo = armor.alsar, let alsar = model.alsar(alsarInfo.arma),
        alsar.skipARMO != true, let formID = armor.id.fullIntFormID
      {
        let mode = alsarInfo.mode
        if mode == .off {
          armo += "# "
        }

        let hexForm = String(format: "%08X", formID)
        let dlc = armor.id.alsarDLCCode
        armo += "\(hexForm)\t\(mode.iniChar)\t\(dlc)\t\(alsarInfo.arma)\t\(name)\n"
      }
    }

    let armoURL = iniURL.appending(path: "zzLSARSetting_ARMO.ini")
    try armo.write(to: armoURL)
  }

  /// Write out the ARMA settings file.
  func writeARMASettings(armors: [(String, ArmorRecord)], iniURL: URL, model: ModelManager) throws {
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

    arma += try filteredARMAChunk(
      armors: armors, filter: .clothing, filterName: "CLOTH", model: model)
    arma += try filteredARMAChunk(
      armors: armors, filter: .light, filterName: "LIGHT_ARMOR", model: model)
    arma += try filteredARMAChunk(
      armors: armors, filter: .heavy, filterName: "HEAVY_ARMOR", model: model)
    arma += try filteredARMAChunk(armors: armors, filter: .mask, filterName: "HELMET", model: model)

    arma += "# END OF LINE\n"

    let armaURL = iniURL.appending(path: "zzLSARSetting_ARMA.ini")
    try arma.write(to: armaURL)
  }

  /// Get a chunk of ARMA entries filtered by keyword.
  // TODO: add ALSAR records to ModelManager
  // TODO: armor ALSAR record should just be an ARMA name and a mode
  // TODO: ALSAR record can leave out editorID unless it doesn't match the predicted one
  // TODO: ALSAR record can leave out mod value (always)
  func filteredARMAChunk(
    armors: [(String, ArmorRecord)], filter: Keyword, filterName: String, model: ModelManager
  ) throws -> String {
    var done = Set<String>()

    var lines: [(String, String)] = []
    for (_, armor) in armors {
      guard let alsarInfo = armor.alsar else { continue }
      let arma = alsarInfo.arma
      let mode = alsarInfo.mode
      guard let alsar = model.alsar(arma) else { continue }
      let variant = "\(mode)\(arma)"
      if !done.contains(variant) {
        done.insert(variant)
        if let keywords = armor.keywords, keywords.contains(filter) {
          let category = ARMACategory.fromKeyword(filter)
          var entries: [(String, FormReference)] = []
          if let loose = alsar.loose {
            entries.append(("L", loose))
          }
          if let fitted = alsar.fitted {
            entries.append(("W", fitted))
          }

          for (code, entry) in entries {
            let name = alsar.alias ?? arma
            let predictedName = "zzLSAR\(code)\(category.iniChar)\(name)"
            if let id = entry.rawFormID8, let editorID = entry.editorID {
              if entry.mod != "zzAlsarOutfitMod.esp" {
                print(
                  "Warning: ARMA entry \(name) is in mod \(entry.mod) but expected zzAlsarOutfitMod.esp"
                )
              }
              if editorID != predictedName {
                print(
                  "Warning: ARMA entry \(name) has editorID \(editorID) but expected \(predictedName)"
                )
              }

              let options = alsar.options
              var line = "\(name)\t"
              line += "\(id)\t"
              line += "\(category.iniChar)\t"
              line += "\(code)\t"
              line += "\(options.skirt ? 1 : 0)\t"
              line += "\(options.panty ? 1 : 0)\t"
              line += "\(options.bra ? 1 : 0)\t"
              line += "\(options.greaves ? 1 : 0)\t"
              line += "\(alsar.priority ?? 0)\t"
              line += "\(armor.id.alsarDLCCode)\t"
              line += "\(editorID)\n"
              let sortKey = "\(code)-\(name)"
              lines.append((sortKey, line))
            }
          }
        }
      }
    }

    var arma =
      "#DO_NOT_EDIT_THIS_LINE:\(filterName)-----------------------------------------------\t\t\t\t\t\t\t\t\t\t\n"

    arma +=
      lines
      .sorted { $0.0 < $1.0 }
      .map { $0.1 }
      .joined()

    return arma
  }

}
