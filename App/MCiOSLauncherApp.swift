//
//  MCiOSLauncherApp.swift
//  MC iOS Launcher
//
//  Minecraft: Java Edition launcher for iOS
//  Written from scratch - dijakonal 2026
//

import SwiftUI

@main
struct MCiOSLauncherApp: App {
    @StateObject private var viewModel = LauncherViewModel()
    @StateObject private var jitManager = JITManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(jitManager)
                .onAppear {
                    Task {
                        await jitManager.checkJITStatus()
                    }
                }
        }
    }
}
