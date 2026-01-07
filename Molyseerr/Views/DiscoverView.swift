//
//  DiscoverView.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import SwiftUI
import Kingfisher

/// Discover page - Dynamic slider system matching Seerr web app
/// Fetches slider configuration from server and displays enabled sliders in order
struct DiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @StateObject private var watchlistManager = WatchlistManager.shared
    @EnvironmentObject var configManager: ConfigManager
    @Environment(\.currentTab) private var currentTab

    // Navigation states for studios and networks
    @State private var selectedStudio: Company?
    @State private var selectedNetwork: Company?
    @State private var selectedMedia: MediaResult?

    var body: some View {
        ZStack {
            Color.Seerr.background.ignoresSafeArea()

            Group {
                if viewModel.isLoading && viewModel.allSliders.isEmpty {
                    // Initial loading state
                    loadingView
                        .onAppear { print("📍 DiscoverView: Showing LOADING view") }
                } else if let errorMessage = viewModel.errorMessage {
                    // Error state
                    errorView(message: errorMessage)
                        .onAppear { print("📍 DiscoverView: Showing ERROR view - \(errorMessage)") }
                } else if viewModel.enabledSliders.isEmpty {
                    // Empty state (no enabled sliders)
                    emptyView
                        .onAppear { print("📍 DiscoverView: Showing EMPTY view - enabledSliders count: \(viewModel.enabledSliders.count)") }
                } else {
                    // Display enabled sliders
                    sliderList
                        .onAppear { print("📍 DiscoverView: Showing SLIDER LIST with \(viewModel.enabledSliders.count) sliders") }
                }
            }
        }
        .navigationDestination(item: $selectedStudio) { studio in
            StudioDetailView(studio: studio)
        }
        .navigationDestination(item: $selectedNetwork) { network in
            NetworkDetailView(network: network)
        }
        .navigationDestination(item: $selectedMedia) { mediaResult in
            MediaDetailView(mediaResult: mediaResult)
        }
        .onChange(of: currentTab) { _, newTab in
            // Clear navigation state when user switches away from this tab
            if newTab != .discover {
                print("🔄 Tab switched away from Discover, clearing navigation")
                selectedMedia = nil
                selectedStudio = nil
                selectedNetwork = nil
            }
        }
        .task {
            // Load slider configuration and watchlist when view appears
            await watchlistManager.loadWatchlist()
            await viewModel.fetchSliders()
        }
    }

    // MARK: - Subviews

    /// Loading indicator view
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)

            Text("Loading discover sliders...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    /// Error state view
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Error")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task {
                    await viewModel.refresh()
                }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding()
                    .background(Color.Seerr.indigo)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.borderless)
        }
        .padding()
    }

    /// Empty state view (no enabled sliders)
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Content Available")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("Your administrator has not enabled any discover sliders.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    /// Dynamic slider list with hero banner
    private var sliderList: some View {
        ScrollView {
            // Use LazyVStack for the entire content to improve vertical scroll performance
            LazyVStack(spacing: 0, pinnedViews: []) {
                // Hero Banner (using TMDB trending API) - fullscreen edge-to-edge
                HeroBannerRow()
                    .ignoresSafeArea(edges: [.top, .leading, .trailing])
                    .id("hero-banner")  // Stable ID for better performance

                // Regular slider rows - Each slider loads independently
                ForEach(viewModel.enabledSliders) { slider in
                    DiscoverSliderRow(
                        slider: slider,
                        selectedStudio: $selectedStudio,
                        selectedNetwork: $selectedNetwork,
                        onMediaSelect: { media in
                            selectedMedia = media
                        }
                    )
                    .id(slider.id)  // Stable ID per slider for better diffing
                }
            }
        }
        .ignoresSafeArea(edges: [.top, .leading, .trailing])
    }
}

/// Hero banner row that fetches content for the banner
struct HeroBannerRow: View {
    @State private var items: [MediaResult] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if !items.isEmpty {
                HeroBanner(items: items)
            } else if isLoading {
                ProgressView()
                    .scaleEffect(2.0)
                    .frame(height: 900)
                    .frame(maxWidth: .infinity)
            }
        }
        .task {
            await loadTrending()
        }
    }

    private func loadTrending() async {
        guard items.isEmpty else { return }

        print("🎬 HeroBanner: Loading trending content...")

        do {
            let response = try await SeerrService.shared.getTrending(page: 1)
            items = Array(response.results.prefix(10))  // Take first 10 items
            print("🎬 HeroBanner: Loaded \(items.count) trending items")

            // Debug: Print media types
            for item in items {
                print("📺 HeroBanner item: \(item.title) - type: \(item.mediaType)")
            }
        } catch {
            print("❌ HeroBanner: Failed to load trending: \(error)")
        }

        isLoading = false
    }
}

/// Individual slider row that fetches and displays content for a specific slider type
struct DiscoverSliderRow: View {
    let slider: DiscoverSlider

    // Bindings for navigation
    @Binding var selectedStudio: Company?
    @Binding var selectedNetwork: Company?
    var onMediaSelect: ((MediaResult) -> Void)?

    @State private var items: [MediaResult] = []
    @State private var calendarItems: [CalendarItem] = []  // For Today's Releases
    @State private var showDeletionRequests = false  // For Deletion Requests slider
    @State private var showRecentRequests = false  // For Recent Requests slider
    @State private var showMovieGenres = false  // For Movie Genres slider
    @State private var showTVGenres = false  // For TV Genres slider
    @State private var showStudios = false  // For Studios slider
    @State private var showNetworks = false  // For Networks slider
    @State private var isLoading = false
    @State private var error: String?
    @State private var hasLoaded = false
    @State private var isVisible = false  // Track if slider is actually visible on screen
    @State private var lastRefreshTime: Date?  // Track last refresh for periodic updates

    @Environment(\.scenePhase) private var scenePhase  // Detect app foreground/background

    var body: some View {
        Group {
            if hasLoaded || !items.isEmpty {
                // Only render content after loading OR if we have cached items
                if slider.type == .deletionRequests {
                    if showDeletionRequests {
                        DeletionRequestsRow()
                    }
                } else if slider.type == .todaysReleases {
                    if !calendarItems.isEmpty {
                        TodayReleasesRow(title: slider.displayTitle, items: calendarItems)
                    }
                } else if showRecentRequests {
                    RecentRequestsRow()
                } else if showMovieGenres {
                    MovieGenresRow(title: slider.displayTitle)
                } else if showTVGenres {
                    TVGenresRow(title: slider.displayTitle)
                } else if showStudios {
                    StudiosRow(slider: slider, selectedStudio: $selectedStudio)
                } else if showNetworks {
                    NetworksRow(slider: slider, selectedNetwork: $selectedNetwork)
                } else {
                    HorizontalMediaRow(title: slider.displayTitle, items: items, isLoading: false, onSelect: onMediaSelect)
                }
            } else {
                // Skeleton loading state while not loaded
                HorizontalMediaRow(title: slider.displayTitle, items: [], isLoading: true, onSelect: onMediaSelect)
            }
        }
        .onAppear {
            // Mark as visible when it appears
            isVisible = true
            // Load content when it becomes visible
            Task {
                await loadSliderContent()
            }
        }
        .onDisappear {
            // Mark as not visible when it disappears
            isVisible = false
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Refresh when app comes to foreground
            if newPhase == .active && oldPhase != .active && hasLoaded {
                Task {
                    await refreshIfStale()
                }
            }
        }
    }

    /// Load content for this specific slider type
    private func loadSliderContent() async {
        // Don't reload if we already have items (prevents reloading on tab switch)
        guard !isLoading, items.isEmpty, !hasLoaded else {
            return
        }

        isLoading = true
        error = nil

        // Try to load from cache first for instant display (no throttling needed)
        let cacheKey = String(describing: slider.type.rawValue)
        if let cachedItems = await DiscoverCacheManager.shared.loadCachedSliderContent(for: cacheKey) {
            items = cachedItems
            hasLoaded = true
            isLoading = false

            // Refresh in background without blocking UI
            // Note: Using Task (not detached) to properly capture struct's context
            // This allows the task to be cancelled when the view disappears
            Task(priority: .background) {
                await refreshSliderContent()
            }
            return
        }

        // No cache available, request permission to load (throttling to prevent API overload)
        await SliderLoadingCoordinator.shared.requestLoad()

        // Mark that we'll eventually load
        hasLoaded = true

        do {
            // Special handling for Deletion Requests
            if slider.type == .deletionRequests {
                // Set flag to display DeletionRequestsRow (which manages its own data)
                showDeletionRequests = true
                isLoading = false
            }
            // Special handling for Recent Requests
            else if slider.type == .recentRequests {
                // Set flag to display RecentRequestsRow (which manages its own data)
                showRecentRequests = true
                isLoading = false
            }
            // Special handling for Movie Genres
            else if slider.type == .movieGenres {
                // Set flag to display MovieGenresRow (which manages its own data)
                showMovieGenres = true
                isLoading = false
            }
            // Special handling for TV Genres
            else if slider.type == .tvGenres {
                // Set flag to display TVGenresRow (which manages its own data)
                showTVGenres = true
                isLoading = false
            }
            // Special handling for Studios
            else if slider.type == .studios {
                // Set flag to display StudiosRow (which manages its own data)
                showStudios = true
                isLoading = false
            }
            // Special handling for Networks
            else if slider.type == .networks {
                // Set flag to display NetworksRow (which manages its own data)
                showNetworks = true
                isLoading = false
            }
            // Special handling for Today's Releases
            else if slider.type == .todaysReleases {
                // Fetch calendar items for today
                let today = getCurrentDate()
                calendarItems = try await SeerrService.shared.getUpcomingCalendar(
                    startDate: today,
                    endDate: today,
                    type: "all",
                    watchlistOnly: false
                )
                isLoading = false
            } else {
                // Standard slider content
                items = try await DiscoverContentService.shared.fetchContentForSlider(slider)
                // Cache for next time
                await DiscoverCacheManager.shared.cacheSliderContent(items, for: String(describing: slider.type.rawValue))
                isLoading = false
            }

            // Signal that we're done loading
            await SliderLoadingCoordinator.shared.finishLoad()
        } catch {
            self.error = "Failed to load content"
            isLoading = false

            // Even on error, signal that we're done
            await SliderLoadingCoordinator.shared.finishLoad()
        }
    }

    /// Refresh slider content in background (after displaying cached content)
    private func refreshSliderContent() async {
        let cacheKey = String(describing: slider.type.rawValue)

        do {
            // Fetch fresh content using shared service
            let freshItems = try await DiscoverContentService.shared.fetchContentForSlider(slider)

            // Update UI on main actor without animation (prevents cards from moving around)
            await MainActor.run {
                self.items = freshItems
                self.lastRefreshTime = Date()
            }

            // Cache the fresh data
            await DiscoverCacheManager.shared.cacheSliderContent(freshItems, for: cacheKey)
        } catch {
            // Silent failure - cached content already displayed
            print("⚠️ Background refresh failed for \(slider.displayTitle): \(error)")
        }
    }

    /// Refresh content if it's been more than 5 minutes since last refresh
    private func refreshIfStale() async {
        // Only refresh standard sliders (not special ones)
        guard slider.type != .deletionRequests,
              slider.type != .recentRequests,
              slider.type != .movieGenres,
              slider.type != .tvGenres,
              slider.type != .studios,
              slider.type != .networks,
              slider.type != .todaysReleases else {
            return
        }

        // Check if we need to refresh (5 minutes = 300 seconds)
        let shouldRefresh: Bool
        if let lastRefresh = lastRefreshTime {
            let timeSinceRefresh = Date().timeIntervalSince(lastRefresh)
            shouldRefresh = timeSinceRefresh > 300  // 5 minutes
        } else {
            shouldRefresh = true  // Never refreshed before
        }

        guard shouldRefresh else {
            print("✨ Slider '\(slider.displayTitle)' is still fresh, skipping refresh")
            return
        }

        print("🔄 Refreshing stale content for '\(slider.displayTitle)'")
        await refreshSliderContent()
    }

    /// Get current date in YYYY-MM-DD format
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

#Preview {
    DiscoverView()
        .environmentObject(ConfigManager())
}
