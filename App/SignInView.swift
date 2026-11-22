//
//  SignInView.swift
//  MC iOS Launcher
//
//  Microsoft account sign-in UI
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var viewModel: LauncherViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isSigningIn = false
    @State private var error: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Logo
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("Sign In")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in with your Microsoft account to play Minecraft: Java Edition")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Sign in button
                Button(action: signIn) {
                    if isSigningIn {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        HStack {
                            Image(systemName: "person.fill")
                            Text("Sign In with Microsoft")
                        }
                        .font(.headline)
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .disabled(isSigningIn)
                
                // Error message
                if let error = error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                    .padding(.bottom, 32)
            }
            .padding()
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func signIn() {
        isSigningIn = true
        error = nil
        
        Task {
            do {
                try await viewModel.signIn()
                await MainActor.run {
                    isSigningIn = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSigningIn = false
                    self.error = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(LauncherViewModel())
}
