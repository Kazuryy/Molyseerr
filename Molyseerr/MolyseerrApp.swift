//
//      
//  Molyseerr
//
//  Created by Kazuryy on 23/12/2025.
//

import SwiftUI
import Combine
import Kingfisher

@main
struct MolyseerrApp: App {

    init() {
        configureKingfisher()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }

    /// Configure Kingfisher for optimal tvOS performance
    private func configureKingfisher() {
        // Memory cache limit: 150 MB (aggressive caching for instant loading)
        ImageCache.default.memoryStorage.config.totalCostLimit = 150 * 1024 * 1024

        // Disk cache limit: 1 GB (store more images for longer)
        ImageCache.default.diskStorage.config.sizeLimit = 1024 * 1024 * 1024

        // Keep images for 30 days instead of 7 (more aggressive caching)
        ImageCache.default.diskStorage.config.expiration = .days(30)

        // Clear only expired cache on launch (keep recent cache)
        ImageCache.default.cleanExpiredDiskCache()
    }
}

struct RootView: View {
    @StateObject private var configManager = ConfigManager()
    @StateObject private var watchlistManager = WatchlistManager.shared
    @State private var isValidatingSession = true
    @State private var isPreloadingContent = false
    @State private var preloadProgress: Double = 0.0
    @State private var deepLinkURL: URL?
    @State private var hasStartedTopShelfRefresh = false

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
            } else if isPreloadingContent {
                // Step 2.5: Preloading content on first launch
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 30) {
                        ProgressView(value: preloadProgress, total: 1.0)
                            .progressViewStyle(.linear)
                            .tint(.white)
                            .frame(width: 300)

                        Text("Loading content...")
                            .foregroundColor(.white)
                            .font(.headline)

                        Text("\(Int(preloadProgress * 100))%")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                            .monospacedDigit()
                    }
                }
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

                // Check if this is first launch (no cache) - if so, preload everything upfront
                let hasCache = await DiscoverCacheManager.shared.hasCachedContent(for: "trending")

                if !hasCache {
                    // First launch - show loading screen and preload everything
                    isPreloadingContent = true
                    print("🆕 First launch detected - preloading all content...")

                    // Monitor progress
                    Task {
                        while isPreloadingContent {
                            preloadProgress = await SliderLoadingCoordinator.shared.getPreloadProgress()
                            try? await Task.sleep(nanoseconds: 100_000_000) // Update every 100ms
                        }
                    }

                    await prefetchDiscoverContent()
                    isPreloadingContent = false
                } else {
                    // Has cache - do background refresh
                    Task.detached(priority: .background) {
                        await prefetchDiscoverContent()
                    }
                }

                // ⚡️ Start TopShelf background refresh (ensures instant TopShelf loading)
                if !hasStartedTopShelfRefresh {
                    hasStartedTopShelfRefresh = true
                    await MainActor.run {
                        TopShelfBackgroundRefresher.shared.startAutoRefresh()
                    }
                }
            }
        }
        .onDisappear {
            // Stop TopShelf refresh when app closes
            TopShelfBackgroundRefresher.shared.stopAutoRefresh()
        }
    }

    // MARK: - Prefetching

    /// Prefetch Discover content in background for instant loading
    /// Fetches first 5-10 sliders and caches them before user navigates to Discover page
    private func prefetchDiscoverContent() async {
        do {
            print("🚀 Starting background prefetch of Discover content...")

            // Fetch slider configuration
            let sliders = try await SeerrService.shared.getDiscoverSliders()
            let enabledSliders = sliders.filter { $0.enabled }.sorted { $0.order < $1.order }

            // Count sliders that need loading (exclude special ones)
            let standardSliders = enabledSliders.filter {
                $0.type != .deletionRequests &&
                $0.type != .recentRequests &&
                $0.type != .movieGenres &&
                $0.type != .tvGenres &&
                $0.type != .studios &&
                $0.type != .networks &&
                $0.type != .todaysReleases
            }

            // Start preload mode with total count (ALL standard sliders)
            await SliderLoadingCoordinator.shared.startPreload(totalCount: standardSliders.count)

            print("📋 Found \(enabledSliders.count) enabled sliders, prefetching ALL standard sliders (\(standardSliders.count))...")

            var allPosterURLs: [URL] = []  // Collect all poster URLs for image prefetching

            // Prefetch ALL standard sliders (ensures zero freezing during scroll)
            for slider in standardSliders {

                // Check if already cached
                let cacheKey = String(describing: slider.type.rawValue)
                if await DiscoverCacheManager.shared.hasCachedContent(for: cacheKey) {
                    print("✅ Slider '\(slider.displayTitle)' already cached")

                    // Still collect poster URLs for image prefetching
                    if let cachedItems = await DiscoverCacheManager.shared.loadCachedSliderContent(for: cacheKey) {
                        let posterURLs = cachedItems.compactMap { TMDBImageHelper.posterURL(path: $0.posterPath) }
                        allPosterURLs.append(contentsOf: posterURLs)
                    }
                    continue
                }

                // Fetch and cache content
                do {
                    print("⬇️ Prefetching '\(slider.displayTitle)'...")
                    let items = try await DiscoverContentService.shared.fetchContentForSlider(slider)
                    await DiscoverCacheManager.shared.cacheSliderContent(items, for: cacheKey)
                    print("✅ Cached \(items.count) items for '\(slider.displayTitle)'")

                    // Collect poster URLs for image prefetching
                    let posterURLs = items.compactMap { TMDBImageHelper.posterURL(path: $0.posterPath) }
                    allPosterURLs.append(contentsOf: posterURLs)
                } catch {
                    print("⚠️ Failed to prefetch '\(slider.displayTitle)': \(error)")
                }
            }

            // Finish preload mode
            await SliderLoadingCoordinator.shared.finishPreload()

            // Prefetch poster images using Kingfisher (up to 100 images to avoid memory issues)
            let imagesToPrefetch = Array(allPosterURLs.prefix(100))
            if !imagesToPrefetch.isEmpty {
                print("🖼️ Prefetching \(imagesToPrefetch.count) poster images...")
                await MainActor.run {
                    let prefetcher = ImagePrefetcher(urls: imagesToPrefetch)
                    prefetcher.start()
                }
            }

            print("✅ Background prefetch completed")
        } catch {
            print("❌ Background prefetch failed: \(error)")
            await SliderLoadingCoordinator.shared.finishPreload()
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
