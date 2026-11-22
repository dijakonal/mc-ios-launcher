//
//  ContentView.swift
//  MC iOS Launcher
//
//  Main launcher UI - version selection, profiles, settings, launch
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: LauncherViewModel
    @EnvironmentObject var jitManager: JITManager
    @State private var showingSignIn = false
    @State private var showingProfiles = false
    @State private var showingSettings = false
    @State private var launchError: String?
    
    var body: some View {
        NavigationSplitView {
            // Sidebar - version list and profiles
            sidebar
        } detail: {
            // Main content - launch controls and status
            detailView
        }
        .sheet(isPresented: $showingSignIn) {
            SignInView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingProfiles) {
            ProfilesView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(viewModel)
        }
        .alert("Launch Error", isPresented: .constant(launchError != nil)) {
            Button("OK") { launchError = nil }
        } message: {
            Text(launchError ?? "")
        }
    }
    
    var sidebar: some View {
        List {
            Section("Account") {
                if viewModel.isAuthenticated, let account = viewModel.microsoftAccount {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(account.username)
                                .font(.caption)
                            Text("Signed in")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Button("Sign In") {
                        showingSignIn = true
                    }
                }
            }
            
            Section("Versions") {
                Picker("Version", selection: $viewModel.selectedVersion) {
                    ForEach(viewModel.versions) { version in
                        Text("\(version.id) (\(version.displayType))")
                            .tag(version as MinecraftVersion?)
                    }
                }
                .pickerStyle(.menu)
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                }
            }
            
            Section("Profiles") {
                ForEach(viewModel.profiles) { profile in
                    Button(profile.name) {
                        viewModel.selectedProfile = profile
                    }
                    .foregroundColor(viewModel.selectedProfile?.id == profile.id ? .blue : .primary)
                }
                
                Button(action: { showingProfiles = true }) {
                    Label("Manage Profiles", systemImage: "plus")
                }
            }
            
            Section {
                Button(action: { showingSettings = true }) {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 250)
    }
    
    var detailView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status card
                statusCard
                
                // JIT status
                jitCard
                
                // Launch button
                launchButton
                
                // Version info
                if let version = viewModel.selectedVersion {
                    versionInfo(version)
                }
                
                // Download progress
                if viewModel.isLoading {
                    progressView
                }
            }
            .padding()
        }
    }
    
    var statusCard: some View {
        Card {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: statusIcon)
                        .font(.title)
                        .foregroundColor(statusColor)
                    
                    VStack(alignment: .leading) {
                        Text(statusTitle)
                            .font(.headline)
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    var jitCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: jitManager.jitEnabled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(jitManager.jitEnabled ? .green : .orange)
                    
                    Text("JIT Status")
                        .font(.headline)
                }
                
                Text(jitStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !jitManager.jitEnabled {
                    Picker("JIT Method", selection: $jitManager.jitMethod) {
                        ForEach(JITManager.JITMethod.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Button(action: {
                        Task {
                            await jitManager.enableJIT()
                        }
                    }) {
                        Text("Enable JIT")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    var launchButton: some View {
        Button(action: launch) {
            HStack {
                Image(systemName: "play.fill")
                Text("Launch")
            }
            .font(.title2)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!canLaunch)
    }
    
    func versionInfo(_ version: MinecraftVersion) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Selected Version")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(version.id)
                    .font(.title2)
                
                Text("Type: \(version.displayType)")
                    .font(.caption)
                
                Text("Released: \(version.releaseTime, style: .date)")
                    .font(.caption)
            }
        }
    }
    
    var progressView: some View {
        Card {
            VStack(spacing: 8) {
                HStack {
                    ProgressView(value: viewModel.downloadProgress)
                        .progressViewStyle(.linear)
                    
                    Text("\(Int(viewModel.downloadProgress * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                }
                
                Text(viewModel.downloadStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var canLaunch: Bool {
        viewModel.isAuthenticated &&
        viewModel.selectedVersion != nil &&
        viewModel.selectedProfile != nil &&
        jitManager.jitEnabled
    }
    
    var statusTitle: String {
        if !viewModel.isAuthenticated {
            return "Sign In Required"
        } else if !jitManager.jitEnabled {
            return "JIT Required"
        } else if viewModel.selectedVersion == nil {
            return "Select Version"
        } else {
            return "Ready to Launch"
        }
    }
    
    var statusMessage: String {
        if !viewModel.isAuthenticated {
            return "Sign in with your Microsoft account"
        } else if !jitManager.jitEnabled {
            return "Enable JIT to run Java code"
        } else if viewModel.selectedVersion == nil {
            return "Choose a Minecraft version"
        } else {
            return "Tap Launch to start playing"
        }
    }
    
    var statusIcon: String {
        if !viewModel.isAuthenticated {
            return "person.badge.plus"
        } else if !jitManager.jitEnabled {
            return "exclamationmark.triangle"
        } else {
            return "checkmark.circle"
        }
    }
    
    var statusColor: Color {
        if canLaunch { return .green }
        return .orange
    }
    
    var jitStatusText: String {
        if jitManager.jitEnabled {
            return "JIT is enabled. Java code can run at full speed."
        } else {
            return "JIT is required for Minecraft to run. Select a method and enable it."
        }
    }
    
    // MARK: - Actions
    
    func launch() {
        Task {
            do {
                try await viewModel.launch()
            } catch {
                launchError = error.localizedDescription
            }
        }
    }
}

// MARK: - Reusable Components

struct Card<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(LauncherViewModel())
        .environmentObject(JITManager())
}
