// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// The type of a Skyrim plugin file.
enum ModType: String, Codable {
  /// A typical plugin file (Elder Scrolls Plugin).
  case esp

  /// A light plugin file (Elder Scrolls Light plugin).
  case esl

  /// A master plugin file (Elder Scrolls Master).
  case esm
}
