// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import TestData
import Testing

@testable import SkyrimTools

@Suite struct ModelManagerTests {
  // Shared helpers
  private func makeManager() throws -> (URL, ModelManager) {
    let root = try makeTempDirectory().appending(path: "Data")
    let manager = try ModelManager(dataURL: root)
    return (root, manager)
  }

  private func reloadManager(at root: URL) throws -> ModelManager {
    try ModelManager(dataURL: root)
  }

  private func decode<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(T.self, from: data)
  }

  // Load initial resources and basic persistence
  @Test func testInitialLoad() throws {
    let root = try makeModelDataFixture()
    let manager = try ModelManager(dataURL: root)

    let sampleModName = URL(fileURLWithPath: "SampleMod").lastPathComponent
    let modRecord = try #require(manager.mod(sampleModName))
    #expect(modRecord.armours == ["Armor X", "Armor Y"])  // present
  }

  // Mod APIs
  @Test func testModDefaultSavesAndLoads() throws {
    let (root, manager) = try makeManager()
    _ = manager.mod("TestMod", default: { ModRecord(skipOBody: true, armours: ["A"]) })
    try manager.save()
    let file = root.appending(path: "Mods/TestMod.json")
    let saved: ModRecord = try decode(ModRecord.self, from: file)
    #expect(saved.skipOBody == true)
    #expect(saved.armours == ["A"])
    let reloaded = try reloadManager(at: root)
    #expect(reloaded.mod("TestMod")?.skipOBody == true)
  }

  @Test func testModUpdateSavesAndLoads() throws {
    let (root, manager) = try makeManager()
    manager.updateMod("UpdatedMod", ModRecord(skipRSV: true, outfits: ["O"]))
    try manager.save()
    let file = root.appending(path: "Mods/UpdatedMod.json")
    let saved: ModRecord = try decode(ModRecord.self, from: file)
    #expect(saved.skipRSV == true)
    #expect(saved.outfits == ["O"])
    let reloaded = try reloadManager(at: root)
    #expect(reloaded.mod("UpdatedMod")?.skipRSV == true)
  }

  // Outfit APIs
  @Test func testOutfitDefaultSavesAndLoads() throws {
    let (root, manager) = try makeManager()
    let defaultOutfit = FormReference(
      formID: "0xABCD", editorID: "TO", mod: "Test.esp", name: "Test Outfit")
    _ = manager.outfit("TestOutfit", default: { defaultOutfit })
    try manager.save()
    let file = root.appending(path: "Outfits/TestOutfit.json")
    let saved: FormReference = try decode(FormReference.self, from: file)
    #expect(saved.formID == "0xABCD")
    #expect(saved.mod == "Test.esp")
    #expect(saved.name == "Test Outfit")
    let reloaded = try reloadManager(at: root)
    #expect(reloaded.outfit("TestOutfit")?.spidName == "Test Outfit")
  }

  @Test func testOutfitUpdateSavesAndLoads() throws {
    let (root, manager) = try makeManager()
    let updated = FormReference(
      formID: "0x1234", editorID: "NEW", mod: "New.esp", name: "New Outfit")
    manager.updateOutfit("NewOutfit", updated)
    try manager.save()
    let file = root.appending(path: "Outfits/NewOutfit.json")
    let saved: FormReference = try decode(FormReference.self, from: file)
    #expect(saved.formID == "0x1234")
    #expect(saved.editorID == "NEW")
    #expect(saved.mod == "New.esp")
    #expect(saved.name == "New Outfit")
    let reloaded = try reloadManager(at: root)
    #expect(reloaded.outfit("NewOutfit")?.sleepName == "0x1234|New.esp")
  }

  // Person APIs
  @Test func testPersonDefaultSavesAndLoads() throws {
    let (root, manager) = try makeManager()
    _ = manager.person(
      "TestNPC", default: { PersonRecord(outfit: "TestOutfit", outfitSource: "unit-test") })
    try manager.save()
    let file = root.appending(path: "People/TestNPC.json")
    let saved: PersonRecord = try decode(PersonRecord.self, from: file)
    #expect(saved.outfit == "TestOutfit")
    #expect(saved.outfitSource == "unit-test")
    let reloaded = try reloadManager(at: root)
    #expect(reloaded.person("TestNPC")?.outfit == "TestOutfit")
  }

  @Test func testPersonUpdateSavesAndLoads() throws {
    let (root, manager) = try makeManager()
    var person = PersonRecord(outfit: "A", outfitSource: "orig")
    person.outfitCollisions = [OutfitCollision(outfit: "Other", source: "elsewhere")]
    manager.updatePerson("NPC", person)
    try manager.save()
    let file = root.appending(path: "People/NPC.json")
    let saved: PersonRecord = try decode(PersonRecord.self, from: file)
    #expect(saved.outfit == "A")
    #expect(saved.outfitCollisions?.first?.outfit == "Other")
    let reloaded = try reloadManager(at: root)
    #expect(reloaded.person("NPC")?.outfitCollisions?.first?.source == "elsewhere")
  }

  // Armor APIs
  @Test func testArmorDefaultSavesAndLoads() throws {
    let (root, manager) = try makeManager()
    let ref = FormReference(formID: "0xAA", editorID: "AR", mod: "Mod.esp", name: "Armor")
    _ = manager.armor("Armor", default: { ArmorRecord(id: ref, sleepSets: ["Set1"]) })
    try manager.save()
    let file = root.appending(path: "Armors/Armor.json")
    let saved: ArmorRecord = try decode(ArmorRecord.self, from: file)
    #expect(saved.id.formID == "0xAA")
    #expect(saved.sleepSets == ["Set1"])
    let reloaded = try reloadManager(at: root)
    #expect(reloaded.armor("Armor")?.sleepSets == ["Set1"])
  }

  @Test func testArmorUpdateSavesAndLoads() throws {
    let (root, manager) = try makeManager()
    let ref = FormReference(formID: "0x00BB", editorID: nil, mod: "Mod.esp", name: "ArmorB")
    let updated = ArmorRecord(id: ref, sleepSets: ["S1", "S2"])
    manager.updateArmor("ArmorB", updated)
    try manager.save()
    let file = root.appending(path: "Armors/ArmorB.json")
    let saved: ArmorRecord = try decode(ArmorRecord.self, from: file)
    #expect(saved.id.name == "ArmorB")
    #expect(saved.sleepSets == ["S1", "S2"])
    let reloaded = try reloadManager(at: root)
    #expect(reloaded.armor("ArmorB")?.id.mod == "Mod.esp")
  }
}
