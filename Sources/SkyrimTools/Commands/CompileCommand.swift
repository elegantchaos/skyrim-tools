// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/04/2026.
//  All code (c) 2026 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

/// Compiles Papyrus scripts using the game's Papyrus compiler.
///
/// Includes are derived from the source folder and discovered SDK directories.
/// A temporary flags file is generated for each run and removed afterwards.
struct CompileCommand: LoggableCommand {

  /// Domain errors for compile workflow.
  enum CompileError: Swift.Error, CustomStringConvertible {
    /// Source folder does not exist.
    case sourcePathMissing(String)

    /// Source path is not a directory.
    case sourcePathIsNotDirectory(String)

    /// SDK root does not exist.
    case sdksPathMissing(String)

    /// SDK root is not a directory.
    case sdksPathIsNotDirectory(String)

    /// Papyrus compiler binary does not exist.
    case compilerMissing(String)

    /// Missing required path in settings.
    case missingPath(String)

    /// Path cannot be represented in Windows format for PapyrusCompiler.
    case unconvertibleWindowsPath(String)

    /// Compiler process returned a failure status.
    case compilerFailed(Int32)

    /// User-facing error description.
    var description: String {
      switch self {
      case .sourcePathMissing(let path):
        return "Source path not found: \(path)"
      case .sourcePathIsNotDirectory(let path):
        return "Source path is not a directory: \(path)"
      case .sdksPathMissing(let path):
        return "SDKs path not found: \(path)"
      case .sdksPathIsNotDirectory(let path):
        return "SDKs path is not a directory: \(path)"
      case .compilerMissing(let path):
        return "Papyrus compiler not found: \(path)"
      case .missingPath(let key):
        return "Missing required path in skyrim-tools.json: paths.\(key)"
      case .unconvertibleWindowsPath(let path):
        return
          "Path cannot be converted to Windows format for PapyrusCompiler: \(path). Use /mnt/<drive>/... or a Windows drive path."
      case .compilerFailed(let code):
        return "PapyrusCompiler exited with status code \(code)."
      }
    }
  }

  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "compile",
      abstract: "Compile Papyrus scripts with SDK include paths."
    )
  }

  /// Enable verbose logs.
  @Flag() var verbose: Bool = false

  /// Source folder containing `.psc` files to compile.
  @Option(help: "Source folder containing .psc files.")
  var sourcePath: String

  /// Root SDK folder. Include paths are discovered from child directories.
  @Option(help: "SDK root folder used to discover include directories.")
  var sdksPath: String

  /// Output folder for compiled `.pex` files.
  @Option(help: "Output folder for compiled .pex files.")
  var outputPath: String

  /// Optional path to PapyrusCompiler executable.
  @Option(help: "Optional path to PapyrusCompiler.exe.")
  var compilerPath: String?

  /// Run Papyrus compile.
  mutating func run() throws {
    print("\nCompiling Papyrus scripts...")

    let fm = FileManager.default
    let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)

    let sourceURL = Self.resolvePath(sourcePath, relativeTo: cwd)
    let sdksURL = Self.resolvePath(sdksPath, relativeTo: cwd)
    let outputURL = Self.resolvePath(outputPath, relativeTo: cwd)

    try Self.validateDirectory(
      sourceURL,
      missing: CompileError.sourcePathMissing,
      notDirectory: CompileError.sourcePathIsNotDirectory
    )
    try Self.validateDirectory(
      sdksURL,
      missing: CompileError.sdksPathMissing,
      notDirectory: CompileError.sdksPathIsNotDirectory
    )
    try fm.createDirectory(at: outputURL, withIntermediateDirectories: true)

    let compilerURL = try resolveCompilerURL(cwd: cwd)
    guard fm.fileExists(atPath: compilerURL.path) else {
      throw CompileError.compilerMissing(compilerURL.path)
    }

    let includeURLs = try Self.includeDirectories(sourceURL: sourceURL, sdksURL: sdksURL)
    let includePath = try includeURLs.map { try Self.windowsPath(for: $0.path) }.joined(
      separator: ";")

    let flagsFileURL = try Self.writeTemporaryFlagsFile(outputURL: outputURL, sdksURL: sdksURL)
    defer {
      try? fm.removeItem(at: flagsFileURL)
      try? fm.removeItem(at: flagsFileURL.deletingLastPathComponent())
    }

    let sourceArgument = try Self.windowsPath(for: sourceURL.path)
    let outputArgument = try Self.windowsPath(for: outputURL.path)
    let flagsArgument = try Self.windowsPath(for: flagsFileURL.path)

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [
      compilerURL.path,
      sourceArgument,
      "-a",
      "-o=\(outputArgument)",
      "-i=\(includePath)",
      "-f=\(flagsArgument)",
    ]

    if !verbose {
      process.standardOutput = Pipe()
      process.standardError = Pipe()
    }

    log("Compiler path: \(compilerURL.path)")
    log("Source path: \(sourceArgument)")
    log("Output path: \(outputArgument)")
    log("Includes: \(includePath)")
    log("Flags path: \(flagsArgument)")

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
      throw CompileError.compilerFailed(process.terminationStatus)
    }

    print("Papyrus compile completed: \(outputURL.path)")
  }

  /// Resolve compiler executable from option or settings.
  private func resolveCompilerURL(cwd: URL) throws -> URL {
    if let compilerPath {
      return Self.resolvePath(compilerPath, relativeTo: cwd)
    }

    let (settings, configURL) = try SkyrimToolsSettings.load(from: cwd)
    guard let gamePath = settings.paths.game else {
      throw CompileError.missingPath("game")
    }

    let gameURL = try SkyrimToolsSettings.resolveConfiguredPath(gamePath, relativeTo: configURL)
    return gameURL.appending(path: "Papyrus Compiler/PapyrusCompiler.exe")
  }

  /// Resolve an absolute or working-directory-relative path.
  static func resolvePath(_ path: String, relativeTo cwd: URL) -> URL {
    if path.hasPrefix("/") {
      return URL(fileURLWithPath: path).standardizedFileURL
    }

    return cwd.appending(path: path).standardizedFileURL
  }

  /// Convert a path to Windows format expected by PapyrusCompiler.
  static func windowsPath(for path: String) throws -> String {
    if isWindowsStylePath(path) {
      return path.replacingOccurrences(of: "\\", with: "/")
    }

    if path.hasPrefix("/mnt/") {
      let components = path.split(separator: "/")
      if components.count >= 2, components[0] == "mnt", let driveCharacter = components[1].first {
        let drive = String(driveCharacter).uppercased()
        let tail = components.dropFirst(2).joined(separator: "/")
        if tail.isEmpty {
          return "\(drive):/"
        }
        return "\(drive):/\(tail)"
      }
    }

    throw CompileError.unconvertibleWindowsPath(path)
  }

  /// Return whether a string is already in Windows drive format.
  static func isWindowsStylePath(_ path: String) -> Bool {
    guard path.count >= 3 else {
      return false
    }

    let characters = Array(path)
    return characters[0].isLetter && characters[1] == ":"
      && (characters[2] == "/" || characters[2] == "\\")
  }

  /// Validate that a URL exists and is a directory.
  private static func validateDirectory(
    _ url: URL,
    missing: (String) -> CompileError,
    notDirectory: (String) -> CompileError
  ) throws {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
      throw missing(url.path)
    }

    guard isDirectory.boolValue else {
      throw notDirectory(url.path)
    }
  }

  /// Discover include directories from source and SDK root folders.
  static func includeDirectories(sourceURL: URL, sdksURL: URL) throws -> [URL] {
    var includes: [URL] = [sourceURL]

    let sdkRoots = try directoryChildren(of: sdksURL)
    for sdkRoot in sdkRoots {
      includes.append(sdkRoot)
      includes.append(contentsOf: try directoryChildren(of: sdkRoot))
    }

    return includes
  }

  /// Return direct child directories sorted by path.
  private static func directoryChildren(of url: URL) throws -> [URL] {
    let children = try FileManager.default.contentsOfDirectory(
      at: url,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles]
    )

    return
      try children
      .filter { child in
        let values = try child.resourceValues(forKeys: [.isDirectoryKey])
        return values.isDirectory == true
      }
      .sorted { $0.path < $1.path }
  }

  /// Create a temporary flags file and return its URL.
  static func writeTemporaryFlagsFile(outputURL: URL, sdksURL: URL) throws -> URL {
    let tempDirectory = outputURL.appending(path: ".skyrim-tools-temp")
    try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

    let flagsURL = tempDirectory.appending(path: "PapyrusFlags-\(UUID().uuidString).flg")
    let templateURL = sdksURL.appending(path: "skyrim/TESV_Papyrus_Flags.flg")

    let contents: String
    if let data = try? Data(contentsOf: templateURL),
      let string = String(data: data, encoding: .utf8),
      !string.isEmpty
    {
      contents = string
    } else {
      contents = defaultFlagsTemplate
    }

    try contents.write(to: flagsURL, atomically: true, encoding: .utf8)
    return flagsURL
  }

  /// Fallback template used when no Skyrim SDK flag file is available.
  static let defaultFlagsTemplate = """
    /*
      Format is as follows (whitespace is completely ignored, index must be between 0 and 31 inclusive):
          Flag <name> <index>        // flag is allowed on all types
      or:
          Flag <name> <index> { <list of script, property, variable, or function> } // flag is allowed only on the specified types
    */

    // List of flags for TESV - DO NOT EDIT

    // Flag hides the script or property from the game editor
    Flag Hidden 0
    {
      Script
      Property
    }

    // Flag on an object designates it as the script the condition system will look at
    // Flag on a variable allows the script variable to be examined by the condition system
    Flag Conditional 1
    {
      Script
      Variable
    }
    """
}
