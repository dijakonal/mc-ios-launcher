//
//  ProfilesView.swift
//  MC iOS Launcher
//
//  Profile management UI
//

import SwiftUI

struct ProfilesView: View {
    @EnvironmentObject var viewModel: LauncherViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingNewProfile = false
    @State private var newProfileName = ""
    @State private var newProfileVersion = ""
    @State private var newProfileRenderer = "MobileGlues"
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.profiles) { profile in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(profile.name)
                                .font(.headline)
                            Text("\(profile.versionId) · \(profile.renderer)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if viewModel.selectedProfile?.id == profile.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedProfile = profile
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteProfile(profile)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                
                Button(action: { showingNewProfile = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("New Profile")
                    }
                }
            }
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.saveProfiles()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingNewProfile) {
                newProfileSheet
            }
        }
    }
    
    var newProfileSheet: some View {
        NavigationStack {
            Form {
                Section("Profile Info") {
                    TextField("Profile Name", text: $newProfileName)
                    
                    Picker("Version", selection: $newProfileVersion) {
                        ForEach(viewModel.versions) { version in
                            Text(version.id).tag(version.id)
                        }
                    }
                    
                    Picker("Renderer", selection: $newProfileRenderer) {
                        Text("MobileGlues").tag("MobileGlues")
                        Text("Zink").tag("Zink")
                        Text("GL4ES").tag("GL4ES")
                    }
                }
                
                Section("Performance") {
                    HStack {
                        Text("Java Memory")
                        Slider(value: Binding(
                            get: { Double(viewModel.javaMemoryMB) },
                            set: { viewModel.javaMemoryMB = Int($0) }
                        ), in: 1024...4096, step: 512)
                        Text("\(viewModel.javaMemoryMB) MB")
                            .monospacedDigit()
                    }
                    
                    HStack {
                        Text("Render Distance")
                        Slider(value: Binding(
                            get: { Double(viewModel.renderDistance) },
                            set: { viewModel.renderDistance = Int($0) }
                        ), in: 4...32, step: 2)
                        Text("\(viewModel.renderDistance) chunks")
                            .monospacedDigit()
                    }
                }
            }
            .navigationTitle("New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showingNewProfile = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        viewModel.createProfile(
                            name: newProfileName,
                            versionId: newProfileVersion,
                            renderer: newProfileRenderer
                        )
                        showingNewProfile = false
                    }
                    .disabled(newProfileName.isEmpty || newProfileVersion.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ProfilesView()
        .environmentObject(LauncherViewModel())
}
