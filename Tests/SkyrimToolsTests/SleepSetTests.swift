import Foundation
import Matchable
@testable import SkyrimTools
import Testing

@Suite struct SleepSetTests {
  @Test func encodeProducesExpectedJSON() throws {
    let sleepSet = SleepSet(
      formList: .init(items: ["0x1234|Foo.esp", "0xABCD|Bar.esm"]),
      int: .init(itemmode: 0, version: 110)
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let data = try encoder.encode(sleepSet)
    let json = String(decoding: data, as: UTF8.self)

    try json.assertMatches(
      """
      {
        "formList" : {
          "items" : [
            "0x1234|Foo.esp",
            "0xABCD|Bar.esm"
          ]
        },
        "int" : {
          "itemmode" : 0,
          "version" : 110
        }
      }
      """
    )
  }

  @Test func decodeParsesTemplate() throws {
    let json = """
    {
      "formList": { "items": ["0xAAAA|Baz.esp"] },
      "int": { "itemmode": 2, "version": 110 }
    }
    """

    let decoder: JSONDecoder = .init()
    let sleepSet = try decoder.decode(SleepSet.self, from: Data(json.utf8))

    #expect(sleepSet.formList.items == ["0xAAAA|Baz.esp"])
    #expect(sleepSet.int.itemmode == 2)
    #expect(sleepSet.int.version == 110)
  }

  @Test func emptyTemplateRoundTrips() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let data = try encoder.encode(SleepSet.empty)
    let decoded: SleepSet = try decoder.decode(SleepSet.self, from: data)

    #expect(decoded.formList.items.isEmpty)
    #expect(decoded.int.itemmode == 0)
    #expect(decoded.int.version == 110)
  }
}
