//
//      
//  Molyseerr
//
//  Created by Kazuryy on 23/12/2025.
//

import SwiftUI
import Combine

@main
struct MolyseerrApp: App {

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @StateObject private var configManager = ConfigManager()
    @State private var isValidatingSession = true

    var body: some View {
        Group {
            if isValidatingSession {
                // Show loading state while validating session
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
            } else if !configManager.isConfigured {
                // Step 1: Server configuration
                ServerConfigView()
                    .environmentObject(configManager)
            } else if !configManager.isBackdropsReady {
                // Step 1.5: Loading backdrops (prevents glitch on LoginView)
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                        Text("Loading...")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                    }
                }
            } else if !configManager.isAuthenticated {
                // Step 2: User authentication
                LoginView()
                    .environmentObject(configManager)
            } else {
                // Step 3: Main app - Tab navigation (Discover, Movies, TV Shows)
                MainTabView()
                    .environmentObject(configManager)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            // Validate session on app startup (like Seerr web app does)
            await configManager.validateSession()
            isValidatingSession = false
        }
    }
}
