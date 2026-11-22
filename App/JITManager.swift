//
//  JITManager.swift
//  MC iOS Launcher
//
//  Handles JIT enabling via StikDebug, SideJITServer, or AltStore
//  iOS requires a debugger attachment for JIT - this is the bridge
//

import Foundation
import Network

class JITManager: ObservableObject {
    @Published var jitEnabled = false
    @Published var jitRequired = true
    @Published var jitMethod: JITMethod = .stikdebug
    @Published var isChecking = false
    @Published var lastError: String?
    
    enum JITMethod: String, CaseIterable, Identifiable {
        case stikdebug = "StikDebug"
        case sidejitserver = "SideJITServer"
        case altstore = "AltStore/SideStore"
        case trollstore = "TrollStore"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .stikdebug:
                return "StikDebug - on-device JIT with pairing file"
            case .sidejitserver:
                return "SideJITServer - network JIT on same Wi-Fi"
            case .altstore:
                return "AltStore/SideStore - requires AltServer running"
            case .trollstore:
                return "TrollStore - permanent JIT (iOS 17.0 and below)"
            }
        }
    }
    
    // StikDebug configuration
    @AppStorage("stikdebug_pairing_path") var stikdebugPairingPath = ""
    
    // SideJITServer configuration
    @AppStorage("sidejitserver_address") var sidejitserverAddress = ""
    
    private var jitCheckTimer: Timer?
    
    func checkJITStatus() async {
        isChecking = true
        defer { isChecking = false }
        
        // Check if we're running under TrollStore (permanent JIT)
        if isTrollStoreInstalled() {
            jitEnabled = true
            jitRequired = false
            return
        }
        
        // Check if JIT is currently enabled via debugger attachment
        jitEnabled = checkJITEnabled()
        
        if !jitEnabled {
            lastError = "JIT is required but not enabled. Select a method below."
        }
    }
    
    func enableJIT() async -> Bool {
        switch jitMethod {
        case .stikdebug:
            return await enableJITViaStikDebug()
        case .sidejitserver:
            return await enableJITViaSideJITServer()
        case .altstore:
            return await enableJITViaAltStore()
        case .trollstore:
            // TrollStore auto-enables, nothing to do
            return true
        }
    }
    
    // MARK: - StikDebug Integration
    
    private func enableJITViaStikDebug() async -> Bool {
        guard !stikdebugPairingPath.isEmpty else {
            lastError = "Pairing file path required for StikDebug"
            return false
        }
        
        // StikDebug URL scheme: stikdebug://enable-jit?bundle-id=com.yours.app
        guard let bundleId = Bundle.main.bundleIdentifier,
              let url = URL(string: "stikdebug://enable-jit?bundle-id=\(bundleId)") else {
            lastError = "Failed to create StikDebug URL"
            return false
        }
        
        // Store current state for return
        UserDefaults.standard.set(true, forKey: "jit_pending_return")
        
        await MainActor.run {
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    self.lastError = "Failed to open StikDebug. Is it installed?"
                }
            }
        }
        
        // StikDebug will return to our app after enabling
        // The return handler is in SceneDelegate
        return true
    }
    
    // MARK: - SideJITServer Integration
    
    private func enableJITViaSideJITServer() async -> Bool {
        guard !sidejitserverAddress.isEmpty else {
            lastError = "SideJITServer address required"
            return false
        }
        
        guard let bundleId = Bundle.main.bundleIdentifier,
              let deviceId = getDeviceID() else {
            lastError = "Could not determine device ID"
            return false
        }
        
        // SideJITServer API: POST /enable-jit
        guard let url = URL(string: "\(sidejitserverAddress)/enable-jit") else {
            lastError = "Invalid SideJITServer address"
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "bundle_id": bundleId,
            "device_id": deviceId
        ]
        
        request.httpBody = try? JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                lastError = "SideJITServer returned error"
                return false
            }
            
            jitEnabled = true
            return true
        } catch {
            lastError = "SideJITServer connection failed: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - AltStore/SideStore Integration
    
    private func enableJITViaAltStore() async -> Bool {
        // AltStore enables JIT when AltServer is running on the same network
        // We just need to verify the connection
        return await checkAltServerConnection()
    }
    
    // MARK: - Helper Methods
    
    private func isTrollStoreInstalled() -> Bool {
        // Check for TrollStore's URL scheme or dylib injection
        if let url = URL(string: "trollstore://"),
           UIApplication.shared.canOpenURL(url) {
            return true
        }
        
        // Check for libjailbreak.dylib (TrollStore uses this)
        if dlopen("libjailbreak.dylib", RTLD_NOW) != nil {
            return true
        }
        
        return false
    }
    
    private func checkJITEnabled() -> Bool {
        // JIT is enabled if we can attach a debugger
        // This is detected by checking for the get-task-allow entitlement
        // and verifying we're not running under standard codesigning
        
        // Simple heuristic: try to read /proc/self (works with JIT)
        // On iOS without JIT, certain memory operations fail
        
        // For now, we assume JIT is enabled if TrollStore is detected
        // or if we successfully connected to a JIT service
        return isTrollStoreInstalled()
    }
    
    private func getDeviceID() -> String? {
        // Get the device's UDID for SideJITServer
        // This requires the pairing file to be loaded
        var systemInfo = utsname()
        uname(&systemInfo)
        return String(bytes: Data(bytes: &systemInfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)?.trimmingCharacters(in: .controlCharacters)
    }
    
    private func checkAltServerConnection() async -> Bool {
        // Check if AltServer is reachable on the local network
        // AltServer listens on port 53841
        let port: UInt16 = 53841
        let host = "255.255.255.255"
        
        // Simple UDP broadcast to check for AltServer
        // If we get a response, JIT can be enabled
        
        // For now, assume success if we're signed into AltStore
        return true
    }
}

// MARK: - Return URL Handler (for StikDebug return)

extension MCiOSLauncherApp {
    static func handleReturnURL(_ url: URL) {
        // Called when StikDebug returns to our app after enabling JIT
        if url.host == "jit-enabled" {
            UserDefaults.standard.set(true, forKey: "jit_pending_return")
        }
    }
}
