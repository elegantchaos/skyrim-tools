// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import TestData
import Testing

@testable import SkyrimTools

@Suite struct FileUtilsTests {
  @Test func testStringWriteCreatesParents() throws {
    let root = try makeTempDirectory()
    let target = root.appending(path: "a/b/c.txt")
    try "hello".write(to: target)
    #expect(FileManager.default.fileExists(atPath: target.path))
  }

  @Test func testURLCopyOverwrites() throws {
    let root = try makeTempDirectory()
    let a = root.appending(path: "a.txt")
    let b = root.appending(path: "b.txt")
    try "first".write(to: a)
    try a.copy(to: b)
    #expect(try String(contentsOf: b, encoding: .utf8) == "first")
    try "second".write(to: a)
    try a.copy(to: b)
    #expect(try String(contentsOf: b, encoding: .utf8) == "second")
  }
}
