//
//  LauncherViewModel.swift
//  MC iOS Launcher
//
//  Main launcher logic - version management, profiles, launching
//

import Foundation
import Combine

class LauncherViewModel: ObservableObject {
    @Published var versions: [MinecraftVersion] = []
    @Published var selectedVersion: MinecraftVersion?
    @Published var profiles: [LauncherProfile] = []
    @Published var selectedProfile: LauncherProfile?
    @Published var isLoading = false
    @Published var downloadProgress: Double = 0
    @Published var downloadStatus: String = ""
    @Published var isAuthenticated = false
    @Published var microsoftAccount: MicrosoftAccount?
    
    @AppStorage("selected_renderer") var selectedRenderer = "MobileGlues"
    @AppStorage("java_memory_mb") var javaMemoryMB = 2048
    @AppStorage("render_distance") var renderDistance = 8
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadVersions()
        loadProfiles()
        checkAuth()
    }
    
    // MARK: - Version Management
    
    func loadVersions() {
        isLoading = true
        downloadStatus = "Fetching version manifest..."
        
        Task {
            do {
                // Download Mojang's version manifest
                let manifest = try await VersionManifestDownloader.download()
                
                // Parse and store versions
                versions = manifest.versions.map { v in
                    MinecraftVersion(
                        id: v.id,
                        type: v.type,
                        url: v.url,
                        releaseTime: v.releaseTime
                    )
                }
                
                // Sort by release time, newest first
                versions.sort { $0.releaseTime > $1.releaseTime }
                
                // Select latest release by default
                if let latestRelease = versions.first(where: { $0.type == "release" }) {
                    selectedVersion = latestRelease
                }
                
                isLoading = false
            } catch {
                downloadStatus = "Failed to load versions: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func downloadVersion(_ version: MinecraftVersion) async throws {
        downloadStatus = "Downloading \(version.id)..."
        
        // Download version JSON
        let versionJSON = try await VersionJSONDownloader.download(url: version.url)
        
        // Download client JAR
        let clientJarURL = versionJSON.downloads.client.url
        let clientJarPath = getInstancePath(version: version.id) + "/\(version.id).jar"
        try await FileDownloader.download(url: clientJarURL, to: clientJarPath) { progress in
            self.downloadProgress = progress * 0.5 // First half of download
            self.downloadStatus = "Downloading client JAR... \(Int(progress * 100))%"
        }
        
        // Download libraries
        let librariesPath = getInstancePath(version: version.id) + "/libraries"
        try FileManager.default.createDirectory(atPath: librariesPath, withIntermediateDirectories: true)
        
        var totalLibs = versionJSON.libraries.count
        var downloadedLibs = 0
        
        for library in versionJSON.libraries {
            // Skip if rules exclude this platform
            if let rules = library.rules, !rules.evaluateForPlatform() {
                continue
            }
            
            guard let download = library.downloads?.artifact else { continue }
            
            let libPath = librariesPath + "/\(download.path)"
            let libDir = (libPath as NSString).deletingLastPathComponent
            try FileManager.default.createDirectory(atPath: libDir, withIntermediateDirectories: true)
            
            try await FileDownloader.download(url: download.url, to: libPath) { _ in
                downloadedLibs += 1
                self.downloadProgress = 0.5 + (Double(downloadedLibs) / Double(totalLibs) * 0.5)
                self.downloadStatus = "Downloading libraries... \(downloadedLibs)/\(totalLibs)"
            }
        }
        
        downloadStatus = "Version \(version.id) ready"
    }
    
    // MARK: - Profile Management
    
    func loadProfiles() {
        let defaults = UserDefaults.standard
        let profileKeys = defaults.array(forKey: "profile_keys") as? [String] ?? []
        
        profiles = profileKeys.compactMap { key in
            guard let data = defaults.data(forKey: "profile_\(key)"),
                  let profile = try? JSONDecoder().decode(LauncherProfile.self, from: data) else {
                return nil
            }
            return profile
        }
        
        if profiles.isEmpty {
            // Create default profile
            let defaultProfile = LauncherProfile(
                id: "default",
                name: "Default",
                versionId: "latest",
                javaArgs: "-Xmx2G",
                renderer: "MobileGlues"
            )
            profiles.append(defaultProfile)
            selectedProfile = defaultProfile
            saveProfiles()
        } else {
            selectedProfile = profiles.first
        }
    }
    
    func saveProfiles() {
        let defaults = UserDefaults.standard
        let profileKeys = profiles.map { $0.id }
        defaults.set(profileKeys, forKey: "profile_keys")
        
        for profile in profiles {
            if let data = try? JSONEncoder().encode(profile) {
                defaults.set(data, forKey: "profile_\(profile.id)")
            }
        }
    }
    
    func createProfile(name: String, versionId: String, renderer: String) {
        let profile = LauncherProfile(
            id: UUID().uuidString,
            name: name,
            versionId: versionId,
            javaArgs: "-Xmx\(javaMemoryMB)M",
            renderer: renderer
        )
        profiles.append(profile)
        saveProfiles()
    }
    
    func deleteProfile(_ profile: LauncherProfile) {
        profiles.removeAll { $0.id == profile.id }
        saveProfiles()
    }
    
    // MARK: - Authentication
    
    func checkAuth() {
        // Check for stored Microsoft account token
        if let data = UserDefaults.standard.data(forKey: "microsoft_account"),
           let account = try? JSONDecoder().decode(MicrosoftAccount.self, from: data) {
            // Verify token is still valid
            if account.isTokenValid {
                isAuthenticated = true
                microsoftAccount = account
            } else {
                // Token expired, clear it
                UserDefaults.standard.removeObject(forKey: "microsoft_account")
            }
        }
    }
    
    func signIn() async throws {
        // Microsoft OAuth2 flow
        let auth = MicrosoftAuth()
        let account = try await auth.authenticate()
        
        microsoftAccount = account
        isAuthenticated = true
        
        // Store account (token will be refreshed as needed)
        if let data = try? JSONEncoder().encode(account) {
            UserDefaults.standard.set(data, forKey: "microsoft_account")
        }
    }
    
    func signOut() {
        microsoftAccount = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "microsoft_account")
    }
    
    // MARK: - Launching
    
    func launch() async throws {
        guard let profile = selectedProfile else {
            throw LauncherError.noProfileSelected
        }
        
        guard let version = selectedVersion else {
            throw LauncherError.noVersionSelected
        }
        
        guard isAuthenticated else {
            throw LauncherError.notAuthenticated
        }
        
        // Ensure version is downloaded
        let instancePath = getInstancePath(version: version.id)
        if !FileManager.default.fileExists(atPath: instancePath) {
            try await downloadVersion(version)
        }
        
        // Build launch command
        let launcher = JavaLauncher(
            profile: profile,
            version: version,
            account: microsoftAccount!
        )
        
        try await launcher.launch()
    }
    
    // MARK: - Helpers
    
    func getInstancePath(version: String) -> String {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("instances/\(version)", isDirectory: true).path
    }
}

// MARK: - Models

struct MinecraftVersion: Identifiable, Hashable {
    let id: String
    let type: String
    let url: String
    let releaseTime: Date
    
    var displayType: String {
        switch type {
        case "release": return "Release"
        case "snapshot": return "Snapshot"
        case "old_alpha": return "Old Alpha"
        case "old_beta": return "Old Beta"
        default: return type.capitalized
        }
    }
}

struct LauncherProfile: Identifiable, Codable {
    let id: String
    var name: String
    var versionId: String
    var javaArgs: String
    var renderer: String
    var mods: [ModReference] = []
}

struct ModReference: Codable {
    let platform: String // "modrinth" or "curseforge"
    let projectId: String
    let versionId: String?
}

struct MicrosoftAccount: Codable {
    let xboxLiveToken: String
    let xstsToken: String
    let mcToken: String
    let uuid: String
    let username: String
    let expiresAt: Date
    
    var isTokenValid: Bool {
        Date() < expiresAt.addingTimeInterval(-300) // 5 min buffer
    }
}

// MARK: - Errors

enum LauncherError: LocalizedError {
    case noProfileSelected
    case noVersionSelected
    case notAuthenticated
    case downloadFailed(String)
    case launchFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noProfileSelected: return "No profile selected"
        case .noVersionSelected: return "No version selected"
        case .notAuthenticated: return "Sign in with Microsoft account required"
        case .downloadFailed(let msg): return "Download failed: \(msg)"
        case .launchFailed(let msg): return "Launch failed: \(msg)"
        }
    }
}
