// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/01/2026.
//  All code (c) 2026 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct VortexCommand: AsyncParsableCommand, LoggableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "vortex",
      abstract: "Run HTTP server to provide mod sources for Vortex."
    )
  }

  @Flag() var verbose: Bool = false
  @Option(help: "Port to listen on.") var port: Int = 8765
  @Option(help: "Path to the skyrim-config Data folder.") var dataPath: String?

  mutating func run() async throws {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let dataURL =
      dataPath.map { URL(fileURLWithPath: $0, relativeTo: cwd) }
      ?? cwd.appending(path: "Data")

    guard FileManager.default.fileExists(atPath: dataURL.path) else {
      throw ValidationError("Data path does not exist: \(dataURL.path)")
    }

    log("Starting Vortex mod source server...")
    log("Data path: \(dataURL.path)")
    log("Listening on port \(port)")

    let server = VortexServer(dataURL: dataURL, port: port, verbose: verbose)
    try await server.start()
  }
}

final class VortexServer: NSObject, URLSessionDelegate {
  let dataURL: URL
  let port: Int
  let verbose: Bool

  init(dataURL: URL, port: Int, verbose: Bool) {
    self.dataURL = dataURL
    self.port = port
    self.verbose = verbose
  }

  func start() async throws {
    #if os(Linux)
      // Use simple HTTP server for Linux
      try await startSimpleHTTPServer()
    #else
      // Use URLSession-based server for macOS
      throw ValidationError("HTTP server not yet implemented for this platform")
    #endif
  }

  #if os(Linux)
    func startSimpleHTTPServer() async throws {
      let sockfd = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
      guard sockfd >= 0 else {
        throw ValidationError("Failed to create socket")
      }

      var optval: Int32 = 1
      setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &optval, socklen_t(MemoryLayout<Int32>.size))

      var serverAddr = sockaddr_in()
      serverAddr.sin_family = sa_family_t(AF_INET)
      serverAddr.sin_port = in_port_t(port).bigEndian
      serverAddr.sin_addr.s_addr = INADDR_ANY

      let bindResult = withUnsafePointer(to: &serverAddr) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
          bind(sockfd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
      }

      guard bindResult >= 0 else {
        close(sockfd)
        throw ValidationError("Failed to bind to port \(port)")
      }

      guard listen(sockfd, 5) >= 0 else {
        close(sockfd)
        throw ValidationError("Failed to listen on socket")
      }

      print("Vortex mod source server running on http://localhost:\(port)")
      print("Press Ctrl+C to stop")

      while true {
        var clientAddr = sockaddr_in()
        var clientAddrLen = socklen_t(MemoryLayout<sockaddr_in>.size)

        let clientfd = withUnsafeMutablePointer(to: &clientAddr) {
          $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            accept(sockfd, $0, &clientAddrLen)
          }
        }

        if clientfd >= 0 {
          Task.detached {
            await self.handleClient(clientfd)
          }
        }
      }
    }

    func handleClient(_ clientfd: Int32) async {
      defer { close(clientfd) }

      // Read request
      var buffer = [UInt8](repeating: 0, count: 4096)
      let bytesRead = recv(clientfd, &buffer, buffer.count, 0)

      guard bytesRead > 0 else { return }

      let request = String(bytes: buffer[..<bytesRead], encoding: .utf8) ?? ""
      let lines = request.split(separator: "\r\n")
      guard let requestLine = lines.first else { return }

      let parts = requestLine.split(separator: " ")
      guard parts.count >= 2 else { return }

      let method = String(parts[0])
      let path = String(parts[1])

      if verbose {
        print("[\(method)] \(path)")
      }

      // Handle request
      let response: String
      let contentType: String

      if path == "/mods" {
        let mods = await listMods()
        response = mods
        contentType = "application/json"
      } else if path == "/" {
        response = """
          {"status":"ok","version":"1.0.0","endpoints":["/mods"]}
          """
        contentType = "application/json"
      } else {
        response = """
          {"error":"Not found"}
          """
        contentType = "application/json"
      }

      let httpResponse = """
        HTTP/1.1 200 OK\r
        Content-Type: \(contentType)\r
        Content-Length: \(response.utf8.count)\r
        Access-Control-Allow-Origin: *\r
        \r
        \(response)
        """

      _ = httpResponse.withCString {
        send(clientfd, $0, strlen($0), 0)
      }
    }
  #endif

  func listMods() async -> String {
    do {
      let modsURL = dataURL.appending(path: "../staging")
      guard FileManager.default.fileExists(atPath: modsURL.path) else {
        return #"{"mods":[],"error":"Staging directory not found"}"#
      }

      let contents = try FileManager.default.contentsOfDirectory(
        at: modsURL,
        includingPropertiesForKeys: [.isDirectoryKey]
      )

      var mods: [[String: String]] = []
      for url in contents {
        let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
        if resourceValues.isDirectory == true {
          mods.append([
            "name": url.lastPathComponent,
            "path": url.path,
          ])
        }
      }

      let encoder = JSONEncoder()
      encoder.outputFormatting = .prettyPrinted
      let data = try encoder.encode(["mods": mods])
      return String(data: data, encoding: .utf8) ?? #"{"mods":[]}"#

    } catch {
      return #"{"mods":[],"error":"\(error.localizedDescription)"}"#
    }
  }
}
