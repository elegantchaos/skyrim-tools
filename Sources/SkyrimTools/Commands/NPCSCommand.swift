// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/11/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

struct NPCSCommand: ParsableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "npcs",
      abstract: "Apply multiple NPC configurations."
    )
  }

  @Flag() var verbose: Bool = false
  @Option(help: "Path to a JSON file containing NPC data.") var npcsPath: String?
  @Option(help: "Path to the output .json file for RSV data.") var rsvOutputPath: String?
  @Option(help: "Path to the output .ini for OBody data.") var obodyOutputPath: String?

  mutating func run() throws {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let npcsURL =
      npcsPath.map { URL(fileURLWithPath: $0, relativeTo: cwd) }

    if let npcURL = npcsURL {
      let decoder = JSONDecoder()
      let data = try Data(contentsOf: npcURL)
      let npcCollection = try decoder.decode([String: NPCRecord].self, from: data)
      process(npcs: npcCollection)
    }

    func process(npcs: [String: NPCRecord]) {
      var obodyIds: [String] = []
      var rsvIds: [String] = []
      for (npcID, npc) in npcs {
        if npcID.split(separator: " ").count > 1 {
          print("Invalid NPC ID '\(npcID)' - contains spaces, skipping")
          continue
        }

        if npc.skipOBody != false, let name = npc.name {
          obodyIds.append(name)
        }
        if npc.skipRSV != false {
          rsvIds.append(npcID)
        }
      }

      if let outputURL = obodyOutputPath.map({ URL(fileURLWithPath: $0, relativeTo: cwd) }) {
        processOBody(idList: obodyIds, to: outputURL)
      }

      if let outputURL = rsvOutputPath.map({ URL(fileURLWithPath: $0, relativeTo: cwd) }) {
        processRSV(idList: rsvIds, to: outputURL)
      }
    }

    func processRSV(idList: [String], to url: URL) {
      let ids =
        idList
        .sorted()
        .joined(separator: ",")

      let ini = """
        Keyword = RSVignore|\(ids)
        Keyword = RSVignoreTeeth|\(ids)
        """

      do {
        try ini.write(to: url)
      } catch {
        print("Error writing RSV INI file: \(error)")
      }
    }

    func processOBody(idList: [String], to url: URL) {
      let ids =
        idList
        .sorted()
        .map { "\n      \"\($0)\"" }
        .joined(separator: ",")

      let ini = """
        {
            "blacklistedNpcs" : [\(ids)
            ]
        }
        """

      do {
        try ini.write(to: url)
      } catch {
        print("Error writing OBody INI file: \(error)")
      }
    }
  }
}

struct NPCRecord: Codable {
  /// The formID of the NPC.
  let formID: String?

  /// The esp/esl file the NPC belongs to.
  let mod: String?

  /// The display name of the NPC.
  let name: String?

  /// Should we add the NPC to the blacklist for OBody?
  let skipOBody: Bool?

  /// Should we add the NPC to the blacklist for RSV?
  let skipRSV: Bool?
}
