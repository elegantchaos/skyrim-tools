// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

extension String {
  /// Normalize a hex string by trimming whitespace, removing any `0x` prefix, and uppercasing.
  var cleanHex: String {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    let lowercased = trimmed.lowercased()
    let body = lowercased.hasPrefix("0x") ? String(lowercased.dropFirst(2)) : lowercased
    return "0x" + body.uppercased()
  }
}
