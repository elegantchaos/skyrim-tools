// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/04/2026.
//  All code (c) 2026 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

/// Prepares a staging repository release by generating fomod metadata, committing changes, and tagging the result.
///
/// On success, this command prints the release version to stdout so shell callers can reuse it.
/// If there is nothing to release, it exits successfully without printing a version.
struct PrepareReleaseCommand: LoggableCommand {

  /// Errors for release preparation.
  enum PrepareReleaseError: Swift.Error, CustomStringConvertible {
    /// Required field is missing from metadata.
    case missingMetadataField(String)

    /// Configured staging path does not exist.
    case stagingPathMissing(String)

    /// Configured staging path is not a directory.
    case stagingPathIsNotDirectory(String)

    /// Staging path is not a git repository.
    case notGitRepository(String)

    /// Commit count output could not be parsed.
    case invalidCommitCount(String)

    /// Release tag already exists.
    case releaseTagExists(String)

    /// Git command failed.
    case gitFailed(String, Int32, String)

    /// User-facing error description.
    var description: String {
      switch self {
      case .missingMetadataField(let field):
        return "Missing required field in mod metadata: \(field)"
      case .stagingPathMissing(let path):
        return "Configured staging path does not exist: \(path)"
      case .stagingPathIsNotDirectory(let path):
        return "Configured staging path is not a directory: \(path)"
      case .notGitRepository(let path):
        return "Staging path is not a git repository: \(path)"
      case .invalidCommitCount(let value):
        return "Unable to parse git commit count: \(value)"
      case .releaseTagExists(let tag):
        return "Tag already exists in staging repository: \(tag)"
      case .gitFailed(let command, let status, let errorOutput):
        let suffix = errorOutput.isEmpty ? "" : " \(errorOutput)"
        return "Git command failed (\(status)): \(command)\(suffix)"
      }
    }
  }

  /// Captured process result.
  private struct ProcessResult {
    /// Exit status returned by the child process.
    let status: Int32

    /// Captured stdout as UTF-8.
    let stdout: String

    /// Captured stderr as UTF-8.
    let stderr: String
  }

  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "prepare-release",
      abstract: "Generate fomod metadata, commit staging changes, and create a release tag."
    )
  }

  /// Enable verbose logs.
  @Flag() var verbose: Bool = false

  /// Path to mod JSON that defines content and archive names.
  @Option(help: "Path to mod JSON (e.g. overrides.json).")
  var modPath: String

  /// Run release preparation.
  mutating func run() async throws {
    let fm = FileManager.default
    let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
    let (settings, configURL) = try SkyrimToolsSettings.load(from: cwd)
    let mod = try ModMetadata.load(from: modPath, cwd: cwd)
    let paths = try ModMetadata.derivePaths(settings: settings, configURL: configURL, mod: mod)

    var isDirectory: ObjCBool = false
    guard fm.fileExists(atPath: paths.stagingURL.path, isDirectory: &isDirectory) else {
      throw PrepareReleaseError.stagingPathMissing(paths.stagingURL.path)
    }

    guard isDirectory.boolValue else {
      throw PrepareReleaseError.stagingPathIsNotDirectory(paths.stagingURL.path)
    }

    let gitRepositoryState = try gitOutput(
      ["rev-parse", "--is-inside-work-tree"], in: paths.stagingURL)
    guard gitRepositoryState == "true" else {
      throw PrepareReleaseError.notGitRepository(paths.stagingURL.path)
    }

    let statusOutput = try gitOutput(["status", "--porcelain"], in: paths.stagingURL)
    guard !statusOutput.isEmpty else {
      print("No staging changes detected; nothing to release.", to: &stderr)
      return
    }

    let commitCountString = try gitOutput(["rev-list", "--count", "HEAD"], in: paths.stagingURL)
    guard let currentCommitCount = Int(commitCountString) else {
      throw PrepareReleaseError.invalidCommitCount(commitCountString)
    }

    guard let baseVersion = mod.version, !baseVersion.isEmpty else {
      throw PrepareReleaseError.missingMetadataField("version")
    }

    let buildNumber = currentCommitCount + 1
    let versionString = try ModMetadata.composeVersion(
      baseVersion: baseVersion,
      buildNumber: buildNumber
    )

    let tagLookupStatus = try gitStatus(
      ["show-ref", "--verify", "--quiet", "refs/tags/\(versionString)"],
      in: paths.stagingURL,
      allowedStatuses: [0, 1]
    )
    if tagLookupStatus == 0 {
      throw PrepareReleaseError.releaseTagExists(versionString)
    }

    var buildFomod = BuildFomodCommand()
    buildFomod.verbose = verbose
    buildFomod.modPath = modPath
    buildFomod.buildNumber = buildNumber
    try buildFomod.execute(emitSummary: false)

    try git(["add", "."], in: paths.stagingURL)

    let stagedDiffStatus = try gitStatus(
      ["diff", "--cached", "--quiet"], in: paths.stagingURL, allowedStatuses: [0, 1])
    guard stagedDiffStatus == 1 else {
      print(
        "No committable staging changes detected after git add; nothing to release.", to: &stderr)
      return
    }

    try git(["commit", "-m", "chore: automated staging update"], in: paths.stagingURL)

    let postCommitStatus = try gitOutput(["status", "--porcelain"], in: paths.stagingURL)
    guard postCommitStatus.isEmpty else {
      throw PrepareReleaseError.gitFailed(
        "git status --porcelain", 1, "Repository is not clean after commit.")
    }

    try git(["tag", "-a", versionString, "-m", "Release \(versionString)"], in: paths.stagingURL)

    var buildArchive = BuildArchiveCommand()
    buildArchive.verbose = verbose
    buildArchive.modPath = modPath
    try buildArchive.execute(paths: paths, emitSummary: false)

    var buildManifest = BuildManifestCommand()
    buildManifest.verbose = verbose
    buildManifest.modPath = modPath
    buildManifest.buildNumber = buildNumber
    try buildManifest.execute(mod: mod, paths: paths, buildNumber: buildNumber, emitSummary: false)

    print(versionString)
  }

  /// Run a git command and require a successful exit status.
  private func git(_ arguments: [String], in directory: URL) throws {
    _ = try runGit(arguments, in: directory)
  }

  /// Run a git command and return trimmed stdout.
  private func gitOutput(_ arguments: [String], in directory: URL) throws -> String {
    let result = try runGit(arguments, in: directory)
    return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Run a git command and return its exit status when explicitly allowed.
  private func gitStatus(_ arguments: [String], in directory: URL, allowedStatuses: Set<Int32>)
    throws -> Int32
  {
    let result = try runGit(arguments, in: directory, allowedStatuses: allowedStatuses)
    return result.status
  }

  /// Execute a git subprocess in the staging repository.
  private func runGit(_ arguments: [String], in directory: URL, allowedStatuses: Set<Int32> = [0])
    throws -> ProcessResult
  {
    log("Running git \(arguments.joined(separator: " "))")

    let process = Process()
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()

    process.currentDirectoryURL = directory
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["git"] + arguments
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    try process.run()
    process.waitUntilExit()

    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
    let stdout = String(decoding: stdoutData, as: UTF8.self)
    let stderr = String(decoding: stderrData, as: UTF8.self).trimmingCharacters(
      in: .whitespacesAndNewlines)

    let result = ProcessResult(status: process.terminationStatus, stdout: stdout, stderr: stderr)
    guard allowedStatuses.contains(result.status) else {
      throw PrepareReleaseError.gitFailed(
        "git \(arguments.joined(separator: " "))",
        result.status,
        result.stderr
      )
    }

    return result
  }
}
