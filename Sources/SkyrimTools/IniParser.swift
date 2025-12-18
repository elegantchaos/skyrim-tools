// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

struct IniEntry: Codable {
  /// Parsed key for the line (single word).
  let key: String

  /// The non-comment, non-empty line content.
  let value: String

  /// Any preceding comment lines joined with newlines (may be empty).
  let comment: String

  /// True if the entry's key matches the given test key (case insensitive).
  func matchesKey(_ testKey: String) -> Bool {
    return key.caseInsensitiveCompare(testKey) == .orderedSame
  }
}

/// Helper for parsing INI-like files while preserving preceding comments.
struct IniParser {
  /// Parse the file at the given URL into an array of entries.
  func parse(url: URL) throws -> [IniEntry] {
    let contents = try String(contentsOf: url, encoding: .utf8)
    var entries: [IniEntry] = []
    var pendingComments: [String] = []

    for rawLine in contents.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
      let line = rawLine.trimmingCharacters(in: CharacterSet.whitespaces)

      if line.isEmpty {
        pendingComments.removeAll()
        continue
      }

      if line.hasPrefix(";") {
        let commentText = line.dropFirst().trimmingCharacters(in: CharacterSet.whitespaces)
        pendingComments.append(String(commentText))
        continue
      }

      let parts = line.split(separator: "=", maxSplits: 1)
      guard parts.count == 2 else {
        pendingComments.removeAll()
        continue
      }

      let key = parts[0].trimmingCharacters(in: CharacterSet.whitespaces)
      guard !key.isEmpty,
        key.rangeOfCharacter(from: CharacterSet.whitespacesAndNewlines) == nil
      else {
        pendingComments.removeAll()
        continue
      }

      let value = parts[1].trimmingCharacters(in: CharacterSet.whitespaces)
      let commentBlock = pendingComments.joined(separator: "\n")
      entries.append(IniEntry(key: key, value: value, comment: commentBlock))
      pendingComments.removeAll()
    }

    return entries
  }
}
