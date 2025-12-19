// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Testing

@testable import SkyrimTools

@Suite struct FormReferenceTests {
  @Test func testParseValidReference() throws {
    let ref = try FormReference(
      parse: "0x800~FlowerGirlsDESPID.esp", comment: "Flower Girls outfit to Ysolda")
    #expect(ref.formID == "0x800")
    #expect(ref.mod == "FlowerGirlsDESPID.esp")
    #expect(ref.name == "Flower Girls")
    #expect(ref.spidReference == "Flower Girls")
  }

  @Test func testInvalidFormThrows() {
    #expect(throws: FormReference.ParseError.self) {
      try FormReference(parse: "notHex~Mod.esp", comment: nil)
    }
    #expect(throws: (any Error).self) {
      try FormReference(parse: "0x800 FlowerGirlsDESPID.esp", comment: nil)
    }
    #expect(throws: (any Error).self) {
      try FormReference(parse: "0x800~Unknown.ext", comment: nil)
    }
  }

  @Test func testSleepName() {
    let ref = FormReference(formID: "0xABCD", editorID: nil, mod: "Mod.esp", name: nil)
    #expect(ref.sleepReference == "0xABCD|Mod.esp")
  }
}
