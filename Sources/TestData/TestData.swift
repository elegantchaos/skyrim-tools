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
