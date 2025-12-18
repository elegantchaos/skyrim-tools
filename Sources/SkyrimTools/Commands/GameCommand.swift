// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/11/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

protocol GameCommand {
  var gamePath: String? { get }
}

extension GameCommand {
  var gameURL: URL {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    return
      gamePath.map { URL(fileURLWithPath: $0, relativeTo: cwd) } ?? cwd.appending(path: "Output")
  }

  var dataURL: URL {
    return gameURL.appending(path: "Data")
  }

  var skseURL: URL {
    return dataURL.appending(path: "SKSE/Plugins")
  }
}

extension String {
  var relativeURL: URL? {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    return URL(fileURLWithPath: self, relativeTo: cwd)
  }
}
