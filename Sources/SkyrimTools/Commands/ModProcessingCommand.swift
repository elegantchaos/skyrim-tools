// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/11/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Command protocol for commands that process mod data files.
protocol ModProcessingCommand: LoggableCommand {
  associatedtype ModRecord: Decodable
  var modsPath: String? { get }
  func process(mods: [String: ModRecord], cwd: URL)
}

extension ModProcessingCommand {
  /// Load all the mod data files from the specified directory, decode them, and process them.
  func loadAndProcessMods() throws {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let modsURL = modsPath.map { URL(fileURLWithPath: $0, relativeTo: cwd) }

    guard let modsURL else {
      print("No mods path specified.")
      return
    }

    let decoder = JSONDecoder()
    var mods: [String: ModRecord] = [:]
    for modURL in try FileManager.default.contentsOfDirectory(
      at: modsURL, includingPropertiesForKeys: [])
    {
      do {
        let data = try Data(contentsOf: modURL)
        let mod = try decoder.decode(ModRecord.self, from: data)
        mods[modURL.deletingPathExtension().lastPathComponent] = mod
      } catch {
        print("Error decoding mod at \(modURL): \(error)")
      }
    }

    process(mods: mods, cwd: cwd)
  }
}
