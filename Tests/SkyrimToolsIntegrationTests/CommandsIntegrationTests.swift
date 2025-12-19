// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Subprocess
import TestData
import Testing

final class CommandsIntegrationTests {
  /// Locate the built executable in the package's .build/debug directory.
  private func toolPath() -> String {
    // tests live in skyrim-tools/Tests/SkyrimToolsIntegrationTests
    let thisFile = URL(fileURLWithPath: #filePath)
    let packageRoot =
      thisFile
      .deletingLastPathComponent()  // CommandsIntegrationTests.swift
      .deletingLastPathComponent()  // SkyrimToolsIntegrationTests
      .deletingLastPathComponent()  // Tests
      .deletingLastPathComponent()  // skyrim-tools
    let debugPath = packageRoot.appending(path: ".build/debug/skyrim-tools").path
    return debugPath
  }

  @Test func testMergeCommand() async throws {
    let exe = toolPath()
    let file1 = testData("input1.json").path
    let file2 = testData("input2.json").path
    let result = try await Subprocess.run(
      .name(exe), arguments: ["merge", file1, file2, "--unique-lists"],
      output: .string(limit: 8192)
    )
    #expect(result.terminationStatus == TerminationStatus.exited(0))
    let out = try #require(result.standardOutput)
    #expect(out.contains("\"a\":"))
    #expect(out.contains("\"b\":"))
    #expect(out.contains("\"list\":[1,2,3]"))
  }

  @Test func testNPCSCommand() async throws {
    let exe = toolPath()
    let npcsPath = testData("npcs.json").path
    let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    let rsvOut = tempRoot.appending(path: "RSV.ini").path
    let obodyOut = tempRoot.appending(path: "OBody.json").path

    let result = try await Subprocess.run(
      .name(exe),
      arguments: [
        "npcs",
        "--npcs-path", npcsPath,
        "--rsv-output-path", rsvOut,
        "--obody-output-path", obodyOut,
      ],
      output: .string(limit: 4096)
    )
    #expect(result.terminationStatus == TerminationStatus.exited(0))
    let rsv = try String(contentsOf: URL(fileURLWithPath: rsvOut), encoding: .utf8)
    let obody = try String(contentsOf: URL(fileURLWithPath: obodyOut), encoding: .utf8)
    #expect(rsv.contains("RSVignore|0002,0003") || rsv.contains("RSVignore|0003,0002"))
    #expect(obody.contains("\"Ysolda\""))
    #expect(!obody.contains("\"Belethor\""))
  }

  @Test func testModsCommand() async throws {
    let exe = toolPath()
    // Create a temp directory and copy the mods file
    let tempMods = URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: tempMods, withIntermediateDirectories: true)
    let modFile = testData("[COCO]Lingerie.esp.json")
    try FileManager.default.copyItem(
      at: modFile, to: tempMods.appending(path: "[COCO]Lingerie.esp.json"))
    let modsDir = tempMods.path
    let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    let obodyOut = tempRoot.appending(path: "mods_obody.json").path

    let result = try await Subprocess.run(
      .name(exe),
      arguments: [
        "mods",
        "--mods-path", modsDir,
        "--obody-output-path", obodyOut,
      ],
      output: .string(limit: 4096)
    )
    #expect(result.terminationStatus == TerminationStatus.exited(0))
    let content = try String(contentsOf: URL(fileURLWithPath: obodyOut), encoding: .utf8)
    #expect(content.contains("blacklistedNpcsPluginMale"))
    #expect(content.contains("\"[COCO]Lingerie.esp\""))
  }

  @Test func testExtractCommand() async throws {
    let exe = toolPath()
    // Create a temp directory and copy the input file
    let tempInput = URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: tempInput, withIntermediateDirectories: true)
    let distrFile = testData("sample_DISTR.ini")
    try FileManager.default.copyItem(
      at: distrFile, to: tempInput.appending(path: "sample_DISTR.ini"))
    let inputDir = tempInput.path
    let tempModel = URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: tempModel, withIntermediateDirectories: true)

    let result = try await Subprocess.run(
      .name(exe),
      arguments: [
        "extract",
        "--input-path", inputDir,
        "--model-path", tempModel.path,
      ],
      output: .string(limit: 8192)
    )
    #expect(result.terminationStatus == TerminationStatus.exited(0))

    // Expect extracted records written via ModelManager
    let peopleYsolda = tempModel.appending(path: "People/Ysolda.json")
    let outfit = tempModel.appending(path: "Outfits/FlowerGirls Outfit.json")
    #expect(FileManager.default.fileExists(atPath: peopleYsolda.path))
    #expect(FileManager.default.fileExists(atPath: outfit.path))
  }
}
