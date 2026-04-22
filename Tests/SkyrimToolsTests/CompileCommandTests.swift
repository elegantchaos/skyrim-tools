// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/04/2026.
//  All code (c) 2026 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import TestData
import Testing

@testable import SkyrimTools

@Suite struct CompileCommandTests {

  @Test func windowsPathConvertsMntDrivePath() throws {
    let converted = try CompileCommand.windowsPath(for: "/mnt/e/Steam/steamapps/common/Skyrim Special Edition")
    #expect(converted == "E:/Steam/steamapps/common/Skyrim Special Edition")
  }

  @Test func windowsPathKeepsWindowsStylePath() throws {
    let converted = try CompileCommand.windowsPath(for: "C:\\Games\\Skyrim")
    #expect(converted == "C:/Games/Skyrim")
  }

  @Test func windowsPathRejectsUnconvertiblePath() throws {
    #expect(throws: CompileCommand.CompileError.self) {
      _ = try CompileCommand.windowsPath(for: "/tmp/flags.flg")
    }
  }

  @Test func includeDirectoriesDiscoversSdksAndNestedFolders() throws {
    let root = try makeTempDirectory()
    let source = root.appending(path: "Source")
    let sdks = root.appending(path: "sdks")

    try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: sdks.appending(path: "skse64"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: sdks.appending(path: "xpmse/main"), withIntermediateDirectories: true)

    let includes = try CompileCommand.includeDirectories(sourceURL: source, sdksURL: sdks)
      .map(\.path)

    #expect(includes.contains(source.path))
    #expect(includes.contains(sdks.appending(path: "skse64").path))
    #expect(includes.contains(sdks.appending(path: "xpmse").path))
    #expect(includes.contains(sdks.appending(path: "xpmse/main").path))
  }

  @Test func temporaryFlagsFileUsesSdkTemplateWhenPresent() throws {
    let root = try makeTempDirectory()
    let output = root.appending(path: "Output")
    let sdks = root.appending(path: "sdks")
    let template = sdks.appending(path: "skyrim/TESV_Papyrus_Flags.flg")

    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(
      at: template.deletingLastPathComponent(), withIntermediateDirectories: true)
    try "Flag TestFlag 7".write(to: template, atomically: true, encoding: .utf8)

    let generated = try CompileCommand.writeTemporaryFlagsFile(outputURL: output, sdksURL: sdks)
    let data = try Data(contentsOf: generated)
    let text = String(decoding: data, as: UTF8.self)

    #expect(text == "Flag TestFlag 7")
  }
}
