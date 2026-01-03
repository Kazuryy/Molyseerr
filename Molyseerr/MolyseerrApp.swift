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
    @StateObject private var watchlistManager = WatchlistManager.shared
    @State private var isValidatingSession = true
    @State private var deepLinkURL: URL?

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
                    .environment(\.deepLinkURL, deepLinkURL)
            }
        }
        .preferredColorScheme(.dark)
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .task {
            // Validate session on app startup (like Seerr web app does)
            await configManager.validateSession()
            isValidatingSession = false

            // Load watchlist after authentication
            if configManager.isAuthenticated {
                await watchlistManager.loadWatchlist()
            }
        }
    }

    // MARK: - Deep Link Handling

    /// Handle deep links from TopShelf
    /// Format: molyseerr://media/movie/123 or molyseerr://media/tv/456
    private func handleDeepLink(_ url: URL) {
        print("🔗 Deep link received: \(url)")

        guard url.scheme == "molyseerr" else {
            print("❌ Invalid scheme: \(url.scheme ?? "none")")
            return
        }

        // Only handle deep links when authenticated
        guard configManager.isAuthenticated else {
            print("⚠️ User not authenticated, ignoring deep link")
            return
        }

        // Store the URL to be handled by MainTabView
        deepLinkURL = url
    }
}

// MARK: - Deep Link Environment Key

private struct DeepLinkURLKey: EnvironmentKey {
    static let defaultValue: URL? = nil
}

extension EnvironmentValues {
    var deepLinkURL: URL? {
        get { self[DeepLinkURLKey.self] }
        set { self[DeepLinkURLKey.self] = newValue }
    }
}
