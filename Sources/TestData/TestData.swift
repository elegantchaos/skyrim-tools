// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Return the URL for a bundled test resource by filename.
/// Example: `testData("input1.json")`
public func testData(_ name: String) -> URL {
  let components = name.split(separator: ".", maxSplits: 1)
  let fileName = String(components[0])
  let fileExtension = components.count > 1 ? String(components[1]) : ""
  guard let url = Bundle.module.url(forResource: fileName, withExtension: fileExtension) else {
    fatalError("Could not find test data file: \(name)")
  }
  return url
}

/// Create a unique temporary directory.
@discardableResult
public func makeTempDirectory() throws -> URL {
  let root = URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: UUID().uuidString)
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  return root
}

/// Copy a bundled test resource to a destination, creating parent folders.
@discardableResult
public func copyTestData(_ name: String, to destination: URL) throws -> URL {
  let parent = destination.deletingLastPathComponent()
  try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
  try FileManager.default.copyItem(at: testData(name), to: destination)
  return destination
}

/// Build a model data tree populated with sample resources.
public func makeModelDataFixture() throws -> URL {
  let dataRoot = try makeTempDirectory().appending(path: "Data")
  let samples = [
    ("Mods/SampleMod.json", "SampleMod.json"),
    ("Outfits/FlowerGirls Outfit.json", "FlowerGirls Outfit.json"),
    ("People/Ysolda.json", "Ysolda.json"),
  ]
  for (relative, source) in samples {
    try copyTestData(source, to: dataRoot.appending(path: relative))
  }
  return dataRoot
}
