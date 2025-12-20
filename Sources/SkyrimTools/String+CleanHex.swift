// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

extension String {
  /// Normalize a hex string by trimming whitespace, removing any `0x` prefix, and uppercasing.
  var cleanHex: String {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    let uppercased = trimmed.uppercased()
    let body = uppercased.hasPrefix("0X") ? String(uppercased.dropFirst(2)) : uppercased
    let uint = UInt(body, radix: 16)
    return "0x" + (uint.map { String(format: "%X", $0) } ?? body)
  }
}
