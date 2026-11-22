//
//  SettingsView.swift
//  MC iOS Launcher
//
//  Settings UI - JIT configuration, renderer, advanced options
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: LauncherViewModel
    @EnvironmentObject var jitManager: JITManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                // JIT Configuration
                Section("JIT Configuration") {
                    Picker("JIT Method", selection: $jitManager.jitMethod) {
                        ForEach(JITManager.JITMethod.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    
                    if jitManager.jitMethod == .stikdebug {
                        HStack {
                            Text("Pairing File")
                            Spacer()
                            Text(jitManager.stikdebugPairingPath.isEmpty ? "Not set" : "Configured")
                                .foregroundColor(.secondary)
                        }
                        .onTapGesture {
                            // Would open file picker for pairing file
                        }
                    }
                    
                    if jitManager.jitMethod == .sidejitserver {
                        TextField("SideJITServer Address", text: $jitManager.sidejitserverAddress)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }
                    
                    Button(action: {
                        Task {
                            await jitManager.enableJIT()
                        }
                    }) {
                        HStack {
                            Image(systemName: jitManager.jitEnabled ? "checkmark.circle.fill" : "bolt.fill")
                                .foregroundColor(jitManager.jitEnabled ? .green : .orange)
                            Text(jitManager.jitEnabled ? "JIT Enabled" : "Enable JIT")
                        }
                    }
                }
                
                // Graphics
                Section("Graphics") {
                    Picker("Renderer", selection: $viewModel.selectedRenderer) {
                        Text("MobileGlues (Recommended)").tag("MobileGlues")
                        Text("Zink").tag("Zink")
                        Text("GL4ES (Legacy)").tag("GL4ES")
                    }
                    
                    HStack {
                        Text("Render Distance")
                        Slider(value: Binding(
                            get: { Double(viewModel.renderDistance) },
                            set: { viewModel.renderDistance = Int($0) }
                        ), in: 4...32, step: 2)
                        Text("\(viewModel.renderDistance)")
                            .monospacedDigit()
                    }
                    
                    Toggle("Shaders", isOn: .constant(false))
                        .disabled(true) // Requires Iris mod
                }
                
                // Performance
                Section("Performance") {
                    HStack {
                        Text("Java Memory")
                        Slider(value: Binding(
                            get: { Double(viewModel.javaMemoryMB) },
                            set: { viewModel.javaMemoryMB = Int($0) }
                        ), in: 1024...4096, step: 256)
                        Text("\(viewModel.javaMemoryMB) MB")
                            .monospacedDigit()
                    }
                    
                    Text("Higher values improve performance but may cause crashes on low-memory devices.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Account
                Section("Account") {
                    if viewModel.isAuthenticated, let account = viewModel.microsoftAccount {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(account.username)
                                    .font(.headline)
                                Text("UUID: \(account.uuid.prefix(8))...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button(role: .destructive) {
                            viewModel.signOut()
                        } label: {
                            Text("Sign Out")
                        }
                    } else {
                        Button("Sign In") {
                            // Would present sign-in sheet
                        }
                    }
                }
                
                // Advanced
                Section("Advanced") {
                    Toggle("Show FPS", isOn: .constant(true))
                    Toggle("Fullscreen", isOn: .constant(false))
                    
                    Link("View Logs", destination: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]))
                    
                    Button("Clear Cache") {
                        clearCache()
                    }
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("GitHub", destination: URL(string: "https://github.com/dijakonal/mc-ios-launcher")!)
                    
                    Text("Built from scratch for iOS. Uses prebuilt SDL3, LWJGL, and OpenJDK binaries.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func clearCache() {
        // Clear downloaded assets, libraries cache
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let cacheDir = documents.appendingPathComponent("cache")
        try? fileManager.removeItem(at: cacheDir)
    }
}

#Preview {
    SettingsView()
        .environmentObject(LauncherViewModel())
        .environmentObject(JITManager())
}
