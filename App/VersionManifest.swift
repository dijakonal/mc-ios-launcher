//
//  VersionManifest.swift
//  MC iOS Launcher
//
//  Downloads and parses Mojang's version manifest
//

import Foundation

struct VersionManifest: Codable {
    let latest: LatestVersions
    let versions: [VersionMeta]
    
    struct LatestVersions: Codable {
        let release: String
        let snapshot: String
    }
    
    struct VersionMeta: Codable, Identifiable {
        let id: String
        let type: String
        let url: String
        let time: String
        let releaseTime: String
        
        var parsedReleaseTime: Date {
            ISO8601DateFormatter().date(from: releaseTime) ?? Date()
        }
    }
}

struct VersionJSON: Codable {
    let id: String
    let type: String
    let mainClass: String
    let inheritsFrom: String?
    let libraries: [Library]
    let downloads: Downloads
    let arguments: Arguments?
    let javaVersion: JavaVersion?
    
    struct Downloads: Codable {
        let client: ClientDownload
        
        struct ClientDownload: Codable {
            let url: String
            let sha1: String
            let size: Int
        }
    }
    
    struct Library: Codable {
        let name: String
        let downloads: LibraryDownloads?
        let rules: [Rule]?
        let natives: [String: String]?
        
        struct LibraryDownloads: Codable {
            let artifact: Artifact?
            
            struct Artifact: Codable {
                let url: String
                let path: String
                let sha1: String
                let size: Int
            }
        }
    }
    
    struct Rule: Codable {
        let action: String
        let os: OSRule?
        
        struct OSRule: Codable {
            let name: String
        }
        
        func evaluateForPlatform() -> Bool {
            guard let os = os else { return action == "allow" }
            let isAllowed = action == "allow"
            
            #if os(iOS) || os(macOS)
            return isAllowed == (os.name == "osx")
            #else
            return !isAllowed
            #endif
        }
    }
    
    struct Arguments: Codable {
        let game: [Argument]?
        let jvm: [Argument]?
        
        enum Argument: Codable {
            case string(String)
            case rule(RuleArgument)
            
            struct RuleArgument: Codable {
                let rules: [Rule]
                let value: String
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let str = try? container.decode(String.self) {
                    self = .string(str)
                } else if let rule = try? container.decode(RuleArgument.self) {
                    self = .rule(rule)
                } else {
                    throw DecodingError.typeMismatch(Argument.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid argument type"))
                }
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .string(let str): try container.encode(str)
                case .rule(let rule): try container.encode(rule)
                }
            }
        }
    }
    
    struct JavaVersion: Codable {
        let majorVersion: Int
        let component: String
    }
}

class VersionManifestDownloader {
    static let manifestURL = "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"
    
    static func download() async throws -> VersionManifest {
        guard let url = URL(string: manifestURL) else {
            throw DownloadError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw DownloadError.httpError
        }
        
        return try JSONDecoder().decode(VersionManifest.self, from: data)
    }
}

class VersionJSONDownloader {
    static func download(url: String) async throws -> VersionJSON {
        guard let url = URL(string: url) else {
            throw DownloadError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw DownloadError.httpError
        }
        
        return try JSONDecoder().decode(VersionJSON.self, from: data)
    }
}

class FileDownloader {
    static func download(url: String, to destination: String, progress: ((Double) -> Void)? = nil) async throws {
        guard let url = URL(string: url) else {
            throw DownloadError.invalidURL
        }
        
        let delegate = DownloadDelegate(progressHandler: progress)
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        
        let downloadTask = session.downloadTask(with: url)
        downloadTask.resume()
        
        // Wait for download to complete
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            delegate.completionHandler = { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        // Move to final destination
        try FileManager.default.moveItem(at: delegate.tempURL!, to: URL(fileURLWithPath: destination))
    }
}

private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    var progressHandler: ((Double) -> Void)?
    var completionHandler: ((Error?) -> Void)?
    var tempURL: URL?
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        tempURL = location
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        progressHandler?(progress)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        completionHandler?(error)
    }
}

enum DownloadError: LocalizedError {
    case invalidURL
    case httpError
    case fileSystemError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .httpError: return "HTTP request failed"
        case .fileSystemError: return "File system operation failed"
        }
    }
}
