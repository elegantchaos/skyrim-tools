// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/01/2026.
//  All code (c) 2026 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

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
    formID: UInt, mode: ARMOMode, dlc: Int, arma: String
  ) {
    self.formID = formID
    self.mode = mode
    self.dlc = dlc
    self.arma = arma
  }

  let formID: UInt
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

  var alsarKeywords: [Keyword] {
    switch self {
    case .cloth:
      return [.alsar, .clothing]
    case .light:
      return [.alsar, .armor, .light]
    case .heavy:
      return [.alsar, .armor, .heavy]
    default:
      return [.alsar, .mask]
    }
  }

  static func fromKeyword(_ keyword: Keyword) -> Self {
    switch keyword {
    case .clothing:
      return .cloth
    case .light:
      return .light
    case .heavy:
      return .heavy
    default:
      return .other
    }
  }

  /// Initialize from ini character.
  static func fromIni(_ char: String) -> Self {
    switch char {
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

  /// Character for ini file.
  var iniChar: String {
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
    category: ARMACategory, dlc: Int, priority: Int, loose: ARMAEntry?, fitted: ARMAEntry?,
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
  let loose: ARMAEntry?
  let fitted: ARMAEntry?
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

  /// Initialize from ini character.
  static func fromIni(_ char: String) -> Self {
    switch char {
    case "L":
      return .loose
    case "W":
      return .fitted
    default:
      return .off
    }
  }

  /// Character for ini file.
  var iniChar: String {
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

/// Options for an ARMA record.
struct ARMAOptions: Codable, Equatable {
  let skirt: Bool
  let panty: Bool
  let bra: Bool
  let greaves: Bool

  /// Initialise, defaulting to standard settings.
  init(skirt: Bool? = nil, panty: Bool? = nil, bra: Bool? = nil, greaves: Bool? = nil) {
    self.skirt = skirt ?? Self.default.skirt
    self.panty = panty ?? Self.default.panty
    self.bra = bra ?? Self.default.bra
    self.greaves = greaves ?? Self.default.greaves
  }

  static let none = ARMAOptions(skirt: false, panty: false, bra: false, greaves: false)
  static let all = ARMAOptions(skirt: true, panty: true, bra: true, greaves: true)
  static let `default` = ARMAOptions(skirt: true, panty: true, bra: false, greaves: true)
}

extension FormReference {
  var alsarDLCCode: Int {
    switch mod?.lowercased() {
    case "dawnguard.esm": return 1
    case "dragonborn.esm": return 3
    default: return 0
    }
  }
}
