// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import TestData
import Testing

@testable import SkyrimTools

@Suite struct IniParserTests {
  @Test func testParsesEntriesWithComments() throws {
    let ini = """
      ; First comment
      ; Second comment
      Outfit = 0x800~FlowerGirlsDESPID.esp|Ysolda

      ; Ignored entry
      Bad Entry

      Keyword=RSVignore|Ysolda
      """
    let temp = try makeTempDirectory()
    let file = temp.appending(path: "test.ini")
    try ini.write(to: file, atomically: true, encoding: .utf8)

    let parser = IniParser()
    let entries = try parser.parse(url: file)

    #expect(entries.count == 2)
    #expect(entries[0].matchesKey("Outfit"))
    #expect(entries[1].matchesKey("Keyword"))
    #expect(entries[0].comment.split(separator: "\n").count == 2)
  }
}
