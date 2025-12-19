// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/12/2025.
//  All code (c) 2025 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public enum TestData {
  /// Return the URL for a bundled test resource.
  /// Pass nested paths like "Merge/input1".
  public static func resourceURL(_ path: String, ext: String? = nil) -> URL? {
    Bundle.module.url(forResource: path, withExtension: ext)
  }
}
