// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import TestData
import Testing

@testable import SkyrimTools

extension Bundle {
  fileprivate static let testData: Bundle = {
    // Find the bundle relative to the test source file location
    let testFileURL = URL(fileURLWithPath: #filePath)
    let packageRoot = testFileURL.deletingLastPathComponent().deletingLastPathComponent()
      .deletingLastPathComponent()
    let buildDir = packageRoot.appending(path: ".build/arm64-apple-macosx/debug")
    let bundleURL = buildDir.appending(path: "skyrim-tools_TestData.bundle")

    if let bundle = Bundle(url: bundleURL) {
      return bundle
    }

    fatalError("Could not locate TestData bundle at \(bundleURL.path)")
  }()

  static func testData(_ name: String) -> URL {
    let components = name.split(separator: ".", maxSplits: 1)
    let fileName = String(components[0])
    let fileExtension = components.count > 1 ? String(components[1]) : ""
    guard let url = testData.url(forResource: fileName, withExtension: fileExtension) else {
      fatalError("Could not find test data file: \(name)")
    }
    return url
  }
}

@Suite struct ModelManagerTests {
  @Test func testLoadAndMigrationFromResources() throws {
    let fm = FileManager.default
    let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: UUID().uuidString)
    try fm.createDirectory(at: tempRoot, withIntermediateDirectories: true)

    // Recreate Data folder structure and copy test files
    let dataTempURL = tempRoot.appending(path: "Data")
    try fm.createDirectory(
      at: dataTempURL.appending(path: "Mods"), withIntermediateDirectories: true)
    try fm.createDirectory(
      at: dataTempURL.appending(path: "Outfits"), withIntermediateDirectories: true)
    try fm.createDirectory(
      at: dataTempURL.appending(path: "People"), withIntermediateDirectories: true)

    try fm.copyItem(
      at: Bundle.testData("SampleMod.json"),
      to: dataTempURL.appending(path: "Mods/SampleMod.json"))
    try fm.copyItem(
      at: Bundle.testData("FlowerGirls Outfit.json"),
      to: dataTempURL.appending(path: "Outfits/FlowerGirls Outfit.json"))
    try fm.copyItem(
      at: Bundle.testData("Ysolda.json"),
      to: dataTempURL.appending(path: "People/Ysolda.json"))

    let manager = try ModelManager(dataURL: dataTempURL)

    // Migration should create armor records from SampleMod.json
    #expect(manager.armor("Armor X") != nil)
    #expect(manager.armor("Armor Y") != nil)

    // Mod should be updated with sorted armours
    let sampleModName = URL(fileURLWithPath: "SampleMod").lastPathComponent
    let modRecord = manager.mod(sampleModName)
    #expect(modRecord != nil)
    #expect(modRecord?.armours == ["Armor X", "Armor Y"])  // sorted

    // Create and update records, then save
    _ = manager.mod("TestMod", default: { ModRecord(skipOBody: true) })
    _ = manager.outfit(
      "TestOutfit",
      default: {
        FormReference(formID: "0x0000ABCD", editorID: "TO", mod: "Test.esp", name: "Test Outfit")
      })
    var person = manager.person(
      "TestNPC", default: { PersonRecord(outfit: "TestOutfit", outfitSource: "unit-test") })
    person.outfitCollisions = [OutfitCollision(outfit: "Other", source: "elsewhere")]
    manager.updatePerson("TestNPC", person)

    try manager.save()

    // Files should exist
    #expect(fm.fileExists(atPath: dataTempURL.appending(path: "Mods/TestMod.json").path))
    #expect(
      fm.fileExists(atPath: dataTempURL.appending(path: "Outfits/TestOutfit.json").path))
    #expect(fm.fileExists(atPath: dataTempURL.appending(path: "People/TestNPC.json").path))

    // Reload should preserve data
    let manager2 = try ModelManager(dataURL: dataTempURL)
    #expect(manager2.mod("TestMod")?.skipOBody == true)
    #expect(manager2.outfit("TestOutfit")?.spidName == "Test Outfit")
    #expect(manager2.person("TestNPC")?.outfit == "TestOutfit")
    #expect(manager2.person("TestNPC")?.outfitCollisions?.first?.outfit == "Other")
  }
}
