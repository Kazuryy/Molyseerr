//
//  TopShelfConfigView.swift
//  Molyseerr
//
//  Created by Claude on 02/01/2026.
//

import SwiftUI
import Combine

/// TopShelf slider configuration view
struct TopShelfConfigView: View {

    // MARK: - State

    @StateObject private var viewModel = TopShelfConfigViewModel()
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        List {
            // Display Mode Section
            Section {
                TopShelfDisplayModeRow(
                    "Display Mode",
                    selection: $viewModel.displayMode
                )
            } header: {
                Text("Display Style")
            } footer: {
                Text(viewModel.displayMode == .hero
                     ? "Hero mode shows one slider with large backdrop images"
                     : "Sectioned mode allows multiple sliders with poster images")
                    .foregroundColor(.Seerr.secondaryText)
            }

            // Slider Selection Section
            Section {
                if viewModel.isLoadingSliders {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .frame(height: 60)
                } else if viewModel.availableSliders.isEmpty {
                    Text("No sliders available. Check your Seerr connection.")
                        .foregroundColor(.Seerr.secondaryText)
                        .frame(height: 60)
                } else {
                    ForEach(viewModel.availableSliders, id: \.id) { slider in
                        TopShelfSliderRow(
                            slider: slider,
                            isSelected: viewModel.isSliderSelected(slider),
                            isDisabled: viewModel.shouldDisableSlider(slider)
                        ) {
                            viewModel.toggleSlider(slider)
                        }
                    }
                }
            } header: {
                Text(viewModel.displayMode == .hero ? "Select Slider (Hero)" : "Select Sliders (Sectioned)")
            } footer: {
                if viewModel.displayMode == .hero {
                    Text("Select one slider for Hero mode")
                        .foregroundColor(.Seerr.secondaryText)
                } else {
                    Text("Select up to 4 sliders for Sectioned mode")
                        .foregroundColor(.Seerr.secondaryText)
                }
            }

            // Actions Section
            Section {
                TopShelfReloadButton {
                    Task {
                        await viewModel.loadSliders()
                    }
                }

                TopShelfRefreshCacheButton {
                    Task {
                        await viewModel.refreshAllSliders()
                    }
                }
            } footer: {
                if let timestamp = TopShelfSettings.shared.cacheTimestamp {
                    let age = Date().timeIntervalSince(timestamp)
                    let minutes = Int(age / 60)
                    Text("Cache last updated \(minutes) minute\(minutes == 1 ? "" : "s") ago")
                        .foregroundColor(.Seerr.secondaryText)
                } else {
                    Text("Cache never updated")
                        .foregroundColor(.Seerr.secondaryText)
                }
            }
        }
        .navigationTitle("TopShelf Configuration")
        .task {
            await viewModel.loadSliders()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class TopShelfConfigViewModel: ObservableObject {

    // MARK: - Published

    @Published var displayMode: TopShelfDisplayMode {
        didSet {
            TopShelfSettings.shared.displayMode = displayMode
            // If switching to hero mode and multiple sliders selected, keep only first
            if displayMode == .hero && selectedSliders.count > 1 {
                selectedSliders = Array(selectedSliders.prefix(1))
                saveSettings()
            }
        }
    }

    @Published var selectedSliders: [TopShelfSliderConfig] = []
    @Published var availableSliders: [TopShelfSlider] = []
    @Published var isLoadingSliders = false
    @Published var showError = false
    @Published var errorMessage: String?

    // MARK: - Properties

    private let settings = TopShelfSettings.shared
    private let seerrService = SeerrService.shared

    // MARK: - Initialization

    init() {
        self.displayMode = settings.displayMode
        self.selectedSliders = settings.selectedSliders

        // Sync Seerr credentials to TopShelf
        syncSeerrCredentials()

        // Refresh cache if stale
        Task {
            await refreshCacheIfNeeded()
        }
    }

    // MARK: - Methods

    func loadSliders() async {
        isLoadingSliders = true
        defer { isLoadingSliders = false }

        do {
            let sliders = try await seerrService.getDiscoverSliders()

            // Filter out unsupported types (genres, studios, networks)
            availableSliders = sliders
                .filter { $0.enabled && TopShelfSettings.isSliderTypeSupported($0.type.rawValue) }
                .sorted { $0.order < $1.order }
                .map { slider in
                    TopShelfSlider(
                        id: slider.id,
                        type: slider.type.rawValue,
                        order: slider.order,
                        enabled: slider.enabled,
                        title: slider.title,
                        data: slider.data
                    )
                }

            print("📱 Loaded \(availableSliders.count) supported sliders")
        } catch {
            errorMessage = "Failed to load sliders: \(error.localizedDescription)"
            showError = true
            print("❌ Failed to load sliders: \(error)")
        }
    }

    func toggleSlider(_ slider: TopShelfSlider) {
        let config = TopShelfSliderConfig(id: slider.id, title: slider.displayTitle, type: slider.type)

        if let index = selectedSliders.firstIndex(where: { $0.id == slider.id }) {
            // Deselect
            selectedSliders.remove(at: index)
        } else {
            // Select
            if displayMode == .hero {
                // Hero mode: replace current selection
                selectedSliders = [config]
            } else {
                // Sectioned mode: add up to 4
                if selectedSliders.count < 4 {
                    selectedSliders.append(config)
                }
            }

            // Cache slider content for TopShelf extension
            Task {
                await cacheSliderContent(slider)
            }
        }

        saveSettings()
    }

    private func cacheSliderContent(_ slider: TopShelfSlider) async {
        print("📦 Caching content for slider: \(slider.displayTitle) (ID: \(slider.id), Type: \(slider.type), Data: \(slider.data ?? "nil"))")

        // Fetch content from Seerr
        do {
            let sliderModel = DiscoverSlider(
                id: slider.id,
                type: SliderType(rawValue: slider.type) ?? .trending,
                order: slider.order,
                isBuiltIn: true,
                enabled: slider.enabled,
                title: slider.title,
                data: slider.data,
                createdAt: "",
                updatedAt: ""
            )

            print("🔍 Created DiscoverSlider model: type=\(sliderModel.type.rawValue), data=\(sliderModel.data ?? "nil")")

            // Fetch content based on slider type
            let items = try await fetchSliderContent(slider: sliderModel)
            print("✅ Fetched \(items.count) items from Seerr")

            // Convert to cache format and fetch logos
            var isFirstItem = true
            var cacheItems: [[String: String]] = []

            for item in items {
                // Extract ID from MediaResult
                let id: Int
                let title: String
                let posterPath: String
                let backdropPath: String
                let overview: String
                let mediaType: String

                switch item {
                case .movie(let movie):
                    id = movie.id
                    title = movie.title ?? ""
                    posterPath = movie.posterPath ?? ""
                    backdropPath = movie.backdropPath ?? ""
                    overview = movie.overview ?? ""
                    mediaType = "movie"
                case .tv(let tv):
                    id = tv.id
                    title = tv.name
                    posterPath = tv.posterPath ?? ""
                    backdropPath = tv.backdropPath ?? ""
                    overview = tv.overview ?? ""
                    mediaType = "tv"
                }

                // Log first item to verify correct content
                if isFirstItem {
                    print("📝 First cached item: \(title) (ID: \(id), type: \(mediaType))")
                    isFirstItem = false
                }

                // Fetch logo from TMDB and create composite image
                var logoPath = ""
                do {
                    let images: TMDBImages
                    if mediaType == "movie" {
                        images = try await TMDBService.shared.getMovieImages(id: id)
                    } else {
                        images = try await TMDBService.shared.getTVImages(id: id)
                    }

                    // Get the best logo (highest vote average, or first if no votes)
                    if let logos = images.logos, !logos.isEmpty {
                        let bestLogo = logos.max(by: { ($0.voteAverage ?? 0) < ($1.voteAverage ?? 0) })
                        logoPath = bestLogo?.filePath ?? ""

                        if !logoPath.isEmpty, !backdropPath.isEmpty {
                            print("🎨 Found logo for '\(title)': \(logoPath)")

                            // Create composite image (backdrop + logo)
                            if let backdropURL = URL(string: "https://image.tmdb.org/t/p/w1280\(backdropPath)"),
                               let logoURL = URL(string: "https://image.tmdb.org/t/p/w500\(logoPath)") {
                                do {
                                    _ = try await TopShelfImageCompositor.shared.compositeImages(
                                        backdropURL: backdropURL,
                                        logoURL: logoURL,
                                        itemId: id
                                    )
                                    print("✅ Created composite image for '\(title)'")
                                } catch {
                                    print("⚠️ Failed to create composite for '\(title)': \(error)")
                                    // Continue - will use plain backdrop
                                }
                            }
                        }
                    }
                } catch {
                    print("⚠️ Failed to fetch logo for '\(title)' (ID: \(id)): \(error)")
                    // Continue without logo
                }

                var dict: [String: String] = [:]
                dict["id"] = "\(id)"
                dict["title"] = title
                dict["mediaType"] = mediaType
                dict["posterPath"] = posterPath
                dict["backdropPath"] = backdropPath
                dict["overview"] = overview
                dict["logoPath"] = logoPath
                cacheItems.append(dict)
            }

            // Save to TopShelf settings
            settings.updateSliderContent(sliderID: slider.id, items: cacheItems)
            print("✅ Cached \(cacheItems.count) items for slider \(slider.id): \(slider.displayTitle)")

            // Verify cache was saved correctly
            let savedCache = settings.sliderContentCache["\(slider.id)"]
            if let first = savedCache?.first {
                print("🔍 Verified cache - First item: \(first["title"] ?? "nil") (ID: \(first["id"] ?? "nil"))")
            }

        } catch {
            print("❌ Failed to cache slider content for \(slider.displayTitle): \(error)")
        }
    }

    private func fetchSliderContent(slider: DiscoverSlider) async throws -> [MediaResult] {
        // Log slider details for debugging
        print("🔍 Fetching content for slider: id=\(slider.id), type=\(slider.type.rawValue), title=\(slider.title ?? "nil"), data=\(slider.data ?? "nil")")

        // Use SliderConfigMapper to get the correct configuration (same as DiscoverView)
        let config = SliderConfigMapper.getConfig(for: slider)

        // Execute request based on configuration
        switch config {
        case .discover(let params):
            return try await executeDiscoverRequest(params: params)

        case .media(let filter, let sort, let take):
            let response = try await seerrService.getMediaList(filter: filter, sort: sort, take: take)
            print("📋 Fetched \(response.results.count) media items from Seerr")

            // MediaInfo from Seerr often has missing titles/posters, so fetch from TMDB
            let results = try await fetchMediaDetailsFromTMDB(response.results)
            print("📋 Converted \(results.count) media items with TMDB data")
            return results

        case .watchlist:
            let items = try await seerrService.getWatchlist()
            print("📋 Fetched \(items.count) watchlist items from Seerr")
            // Reverse to show most recently added items first
            let results = try await fetchWatchlistDetails(items.reversed())
            print("📋 Converted \(results.count) watchlist items with posters (showing most recent first)")
            return results

        case .search(let query):
            let response = try await seerrService.search(query: query)
            return Array(response.results.prefix(20))

        case .available(let mediaType):
            let response = try await seerrService.getAvailableMedia(type: mediaType.rawValue, page: 1, sortBy: "mediaAddedAt")
            return Array(response.results.prefix(20))

        case .studioContent(let id):
            guard let studioId = Int(id) else {
                throw SeerrError.invalidSliderData
            }
            let response = try await seerrService.getMoviesByStudio(studioId: studioId)
            return Array(response.results.prefix(20))

        case .networkContent(let id):
            guard let networkId = Int(id) else {
                throw SeerrError.invalidSliderData
            }
            let response = try await seerrService.getTVByNetwork(networkId: networkId)
            return Array(response.results.prefix(20))

        case .genreSlider, .studioList, .networkList:
            // These require special UI handling, not supported in TopShelf
            throw SeerrError.invalidSliderData

        case .calendar, .request:
            // Not yet implemented for TopShelf
            throw SeerrError.invalidSliderData

        case .error(let message):
            print("⚠️ Slider configuration error: \(message)")
            throw SeerrError.invalidSliderData
        }
    }

    /// Execute discover request based on parameters (same logic as DiscoverView)
    private func executeDiscoverRequest(params: DiscoverParams) async throws -> [MediaResult] {
        switch params {
        case .trending:
            print("📡 Executing discover request: Trending")
            let response = try await seerrService.getTrending()
            return Array(response.results.prefix(20))

        case .movie(let sortBy, let genre, let keywords, let excludeKeywords, let studio, let primaryReleaseDateGte, let primaryReleaseDateLte, let language, _, _, _, _, let watchRegion, let watchProviders):
            print("📡 Executing discover request: Movies - sortBy=\(sortBy), genre=\(genre ?? "nil"), keywords=\(keywords ?? "nil"), studio=\(studio ?? "nil"), watchRegion=\(watchRegion ?? "nil"), watchProviders=\(watchProviders ?? "nil")")
            let response: PaginatedResponse<MovieResult> = try await seerrService.discoverMovies(
                sortBy: sortBy,
                genre: genre,
                keywords: keywords,
                excludeKeywords: excludeKeywords,
                studio: studio,
                primaryReleaseDateGte: primaryReleaseDateGte,
                primaryReleaseDateLte: primaryReleaseDateLte,
                language: language,
                watchRegion: watchRegion,
                watchProviders: watchProviders
            )
            return Array(response.results.map { .movie($0) }.prefix(20))

        case .tv(let sortBy, let genre, let keywords, let excludeKeywords, let network, let firstAirDateGte, let firstAirDateLte, let language, let watchRegion, let watchProviders):
            print("📡 Executing discover request: TV - sortBy=\(sortBy), genre=\(genre ?? "nil"), keywords=\(keywords ?? "nil"), network=\(network ?? "nil"), watchRegion=\(watchRegion ?? "nil"), watchProviders=\(watchProviders ?? "nil")")
            let response: PaginatedResponse<TVResult> = try await seerrService.discoverTV(
                sortBy: sortBy,
                genre: genre,
                keywords: keywords,
                excludeKeywords: excludeKeywords,
                network: network,
                firstAirDateGte: firstAirDateGte,
                firstAirDateLte: firstAirDateLte,
                language: language,
                watchRegion: watchRegion,
                watchProviders: watchProviders
            )
            return Array(response.results.map { .tv($0) }.prefix(20))
        }
    }

    /// Convert MediaInfo to MediaResult
    private func convertMediaInfoToResults(_ mediaInfos: [MediaInfo]) -> [MediaResult] {
        return mediaInfos.compactMap { mediaInfo -> MediaResult? in
            let isMovie = mediaInfo.mediaType == .movie

            if isMovie {
                // Skip items without title
                guard let title = mediaInfo.title, !title.isEmpty else {
                    print("⚠️ Skipping movie with no title (ID: \(mediaInfo.tmdbId))")
                    return nil
                }

                let movie = MovieResult(
                    id: mediaInfo.tmdbId,
                    adult: false,
                    backdropPath: mediaInfo.backdropPath,
                    posterPath: mediaInfo.posterPath,
                    genreIds: mediaInfo.genres?.compactMap { $0.id },
                    originalLanguage: mediaInfo.originalLanguage,
                    originalTitle: mediaInfo.originalTitle,
                    overview: mediaInfo.overview,
                    popularity: mediaInfo.popularity,
                    releaseDate: mediaInfo.releaseDate,
                    firstAirDate: nil,
                    title: title,
                    name: nil,
                    originCountry: nil,
                    originalName: nil,
                    video: false,
                    voteAverage: mediaInfo.voteAverage,
                    voteCount: mediaInfo.voteCount,
                    mediaType: "movie",
                    mediaInfo: mediaInfo
                )
                return .movie(movie)
            } else {
                // Skip items without title
                guard let title = mediaInfo.title, !title.isEmpty else {
                    print("⚠️ Skipping TV show with no title (ID: \(mediaInfo.tmdbId))")
                    return nil
                }

                let tv = TVResult(
                    id: mediaInfo.tmdbId,
                    backdropPath: mediaInfo.backdropPath,
                    posterPath: mediaInfo.posterPath,
                    genreIds: mediaInfo.genres?.compactMap { $0.id },
                    originalLanguage: mediaInfo.originalLanguage,
                    originalName: mediaInfo.originalTitle,
                    overview: mediaInfo.overview,
                    popularity: mediaInfo.popularity,
                    firstAirDate: mediaInfo.firstAirDate,
                    name: title,
                    voteAverage: mediaInfo.voteAverage,
                    voteCount: mediaInfo.voteCount,
                    originCountry: mediaInfo.originCountry,
                    mediaType: "tv",
                    mediaInfo: mediaInfo
                )
                return .tv(tv)
            }
        }
    }

    /// Fetch media details from TMDB (for Recently Added and similar sliders)
    private func fetchMediaDetailsFromTMDB(_ mediaInfos: [MediaInfo]) async throws -> [MediaResult] {
        let tmdbService = TMDBService.shared
        var results: [MediaResult] = []
        var skippedCount = 0

        for mediaInfo in mediaInfos.prefix(20) {
            let tmdbId = mediaInfo.tmdbId

            do {
                if mediaInfo.mediaType == .movie {
                    // Fetch from TMDB for reliable poster/backdrop/title data
                    async let tmdbDetails = tmdbService.getMovieDetails(id: tmdbId)
                    async let seerrDetails = try? seerrService.getMovieDetails(id: tmdbId)

                    let (tmdb, seerr) = try await (tmdbDetails, seerrDetails)

                    // Skip items without poster OR backdrop (need at least one image for TopShelf)
                    let hasPoster = tmdb.posterPath != nil && !tmdb.posterPath!.isEmpty
                    let hasBackdrop = tmdb.backdropPath != nil && !tmdb.backdropPath!.isEmpty

                    guard hasPoster || hasBackdrop else {
                        print("⚠️ Skipping movie '\(tmdb.title)' (ID: \(tmdbId)) - no poster or backdrop")
                        skippedCount += 1
                        continue
                    }

                    let movie = MovieResult(
                        id: tmdb.id,
                        adult: tmdb.adult,
                        backdropPath: tmdb.backdropPath,
                        posterPath: tmdb.posterPath,
                        genreIds: tmdb.genres?.map { $0.id },
                        originalLanguage: tmdb.originalLanguage,
                        originalTitle: tmdb.originalTitle,
                        overview: tmdb.overview,
                        popularity: tmdb.popularity,
                        releaseDate: tmdb.releaseDate,
                        firstAirDate: nil,
                        title: tmdb.title,
                        name: nil,
                        originCountry: nil,
                        originalName: nil,
                        video: false,
                        voteAverage: tmdb.voteAverage,
                        voteCount: tmdb.voteCount,
                        mediaType: "movie",
                        mediaInfo: seerr?.mediaInfo ?? mediaInfo  // Prefer Seerr, fallback to original
                    )
                    results.append(.movie(movie))
                } else {
                    // Fetch from TMDB for reliable poster/backdrop/title data
                    async let tmdbDetails = tmdbService.getTVDetails(id: tmdbId)
                    async let seerrDetails = try? seerrService.getTVDetails(id: tmdbId)

                    let (tmdb, seerr) = try await (tmdbDetails, seerrDetails)

                    // Skip items without poster OR backdrop (need at least one image for TopShelf)
                    let hasPoster = tmdb.posterPath != nil && !tmdb.posterPath!.isEmpty
                    let hasBackdrop = tmdb.backdropPath != nil && !tmdb.backdropPath!.isEmpty

                    guard hasPoster || hasBackdrop else {
                        print("⚠️ Skipping TV show '\(tmdb.name)' (ID: \(tmdbId)) - no poster or backdrop")
                        skippedCount += 1
                        continue
                    }

                    let tv = TVResult(
                        id: tmdb.id,
                        backdropPath: tmdb.backdropPath,
                        posterPath: tmdb.posterPath,
                        genreIds: tmdb.genres?.map { $0.id },
                        originalLanguage: tmdb.originalLanguage,
                        originalName: tmdb.originalName,
                        overview: tmdb.overview,
                        popularity: tmdb.popularity,
                        firstAirDate: tmdb.firstAirDate,
                        name: tmdb.name,
                        voteAverage: tmdb.voteAverage,
                        voteCount: tmdb.voteCount,
                        originCountry: tmdb.originCountry,
                        mediaType: "tv",
                        mediaInfo: seerr?.mediaInfo ?? mediaInfo  // Prefer Seerr, fallback to original
                    )
                    results.append(.tv(tv))
                }
            } catch {
                // Skip items that fail to fetch
                print("⚠️ Failed to fetch media item \(tmdbId): \(error)")
                skippedCount += 1
                continue
            }
        }

        print("✅ Fetched \(results.count) media items with TMDB data (skipped \(skippedCount) items)")
        return results
    }

    /// Fetch watchlist details (same as DiscoverView - use TMDB for images)
    private func fetchWatchlistDetails(_ items: [WatchlistItem]) async throws -> [MediaResult] {
        let tmdbService = TMDBService.shared
        var results: [MediaResult] = []
        var skippedCount = 0

        for item in items.prefix(20) {
            guard let tmdbId = item.tmdbId else {
                print("⚠️ Watchlist item has no TMDB ID, skipping")
                continue
            }

            do {
                if item.mediaTypeEnum == .movie {
                    // Fetch from TMDB for reliable poster/backdrop data
                    async let tmdbDetails = tmdbService.getMovieDetails(id: tmdbId)
                    async let seerrDetails = try? seerrService.getMovieDetails(id: tmdbId)

                    let (tmdb, seerr) = try await (tmdbDetails, seerrDetails)

                    // Skip items without poster OR backdrop (need at least one image for TopShelf)
                    let hasPoster = tmdb.posterPath != nil && !tmdb.posterPath!.isEmpty
                    let hasBackdrop = tmdb.backdropPath != nil && !tmdb.backdropPath!.isEmpty

                    guard hasPoster || hasBackdrop else {
                        print("⚠️ Skipping movie '\(tmdb.title)' (ID: \(tmdbId)) - no poster or backdrop")
                        skippedCount += 1
                        continue
                    }

                    if !hasPoster {
                        print("ℹ️ Movie '\(tmdb.title)' has no poster, using backdrop")
                    }

                    let movie = MovieResult(
                        id: tmdb.id,
                        adult: tmdb.adult,
                        backdropPath: tmdb.backdropPath,
                        posterPath: tmdb.posterPath,  // Use TMDB data for reliable posters
                        genreIds: tmdb.genres?.map { $0.id },
                        originalLanguage: tmdb.originalLanguage,
                        originalTitle: tmdb.originalTitle,
                        overview: tmdb.overview,
                        popularity: tmdb.popularity,
                        releaseDate: tmdb.releaseDate,
                        firstAirDate: nil,
                        title: tmdb.title,
                        name: nil,
                        originCountry: nil,
                        originalName: nil,
                        video: false,
                        voteAverage: tmdb.voteAverage,
                        voteCount: tmdb.voteCount,
                        mediaType: "movie",
                        mediaInfo: seerr?.mediaInfo  // Use Seerr for media status
                    )
                    results.append(.movie(movie))
                } else {
                    // Fetch from TMDB for reliable poster/backdrop data
                    async let tmdbDetails = tmdbService.getTVDetails(id: tmdbId)
                    async let seerrDetails = try? seerrService.getTVDetails(id: tmdbId)

                    let (tmdb, seerr) = try await (tmdbDetails, seerrDetails)

                    // Skip items without poster OR backdrop (need at least one image for TopShelf)
                    let hasPoster = tmdb.posterPath != nil && !tmdb.posterPath!.isEmpty
                    let hasBackdrop = tmdb.backdropPath != nil && !tmdb.backdropPath!.isEmpty

                    guard hasPoster || hasBackdrop else {
                        print("⚠️ Skipping TV show '\(tmdb.name)' (ID: \(tmdbId)) - no poster or backdrop")
                        skippedCount += 1
                        continue
                    }

                    if !hasPoster {
                        print("ℹ️ TV show '\(tmdb.name)' has no poster, using backdrop")
                    }

                    let tv = TVResult(
                        id: tmdb.id,
                        backdropPath: tmdb.backdropPath,
                        posterPath: tmdb.posterPath,  // Use TMDB data for reliable posters
                        genreIds: tmdb.genres?.map { $0.id },
                        originalLanguage: tmdb.originalLanguage,
                        originalName: tmdb.originalName,
                        overview: tmdb.overview,
                        popularity: tmdb.popularity,
                        firstAirDate: tmdb.firstAirDate,
                        name: tmdb.name,
                        voteAverage: tmdb.voteAverage,
                        voteCount: tmdb.voteCount,
                        originCountry: tmdb.originCountry,
                        mediaType: "tv",
                        mediaInfo: seerr?.mediaInfo  // Use Seerr for media status
                    )
                    results.append(.tv(tv))
                }
            } catch {
                // Skip items that fail to fetch
                print("⚠️ Failed to fetch watchlist item \(tmdbId): \(error)")
                skippedCount += 1
                continue
            }
        }

        print("✅ Fetched \(results.count) watchlist items with posters (skipped \(skippedCount) items)")
        return results
    }

    enum SeerrError: Error {
        case invalidSliderData
    }

    func isSliderSelected(_ slider: TopShelfSlider) -> Bool {
        selectedSliders.contains { $0.id == slider.id }
    }


    func shouldDisableSlider(_ slider: TopShelfSlider) -> Bool {
        // In sectioned mode, disable if 4 already selected and this one isn't selected
        if displayMode == .sectioned && selectedSliders.count >= 4 {
            return !isSliderSelected(slider)
        }
        return false
    }

    private func saveSettings() {
        settings.selectedSliders = selectedSliders
        print("💾 Saved \(selectedSliders.count) selected sliders")
    }

    private func syncSeerrCredentials() {
        // Sync Seerr URL to TopShelf settings
        // Note: ConfigManager stores URL with key "seerr_base_url"
        if let url = UserDefaults.standard.string(forKey: "seerr_base_url") {
            settings.seerrURL = url
            print("🔄 Synced Seerr URL to TopShelf: \(url)")
        } else {
            print("⚠️ No Seerr URL found in UserDefaults")
        }

        print("🔄 Synced Seerr credentials to TopShelf")
    }

    /// Refresh cache if it's stale (>15 min old)
    private func refreshCacheIfNeeded() async {
        guard !selectedSliders.isEmpty else {
            print("⏭️ No sliders selected, skipping cache refresh")
            return
        }

        if settings.isCacheStale {
            print("🔄 Cache is stale, refreshing all selected sliders...")
            await refreshAllSliders()
        } else {
            if let timestamp = settings.cacheTimestamp {
                let age = Date().timeIntervalSince(timestamp)
                print("✅ Cache is fresh (\(Int(age/60)) minutes old)")
            }
        }
    }

    /// Refresh cache for all selected sliders
    func refreshAllSliders() async {
        print("🔄 Refreshing cache for \(selectedSliders.count) sliders...")

        // Clear existing cache first to avoid stale data
        settings.clearCache()
        print("🗑️ Cleared existing cache")

        // Reload sliders from Seerr to get fresh data (including `data` field)
        await loadSliders()

        for sliderConfig in selectedSliders {
            // Find full slider info with complete data
            if let slider = availableSliders.first(where: { $0.id == sliderConfig.id }) {
                print("🔄 Refreshing slider: \(slider.displayTitle) (ID: \(slider.id))")
                await cacheSliderContent(slider)
            } else {
                print("⚠️ Slider \(sliderConfig.id) not found in available sliders, skipping")
            }
        }

        print("✅ Cache refresh complete")
    }
}

// MARK: - Custom Components

/// Display Mode selection row (styled like settings)
struct TopShelfDisplayModeRow: View {
    let title: String
    @Binding var selection: TopShelfDisplayMode
    @FocusState private var isFocused: Bool

    init(_ title: String, selection: Binding<TopShelfDisplayMode>) {
        self.title = title
        self._selection = selection
    }

    var body: some View {
        Menu {
            Picker(title, selection: $selection) {
                ForEach(TopShelfDisplayMode.allCases, id: \.rawValue) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(isFocused ? .black : .white)
                    .padding(.leading, 4)

                Spacer()

                Text(selection.displayName)
                    .foregroundStyle(isFocused ? .black : .secondary)
                    .brightness(isFocused ? 0.4 : 0)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.body.weight(.regular))
                    .foregroundStyle(isFocused ? .black : .secondary)
                    .brightness(isFocused ? 0.4 : 0)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFocused ? Color.white : Color.clear)
            )
            .scaleEffect(isFocused ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.125), value: isFocused)
        }
        .menuStyle(.borderlessButton)
        .listRowInsets(EdgeInsets())
        .focused($isFocused)
    }
}

/// Slider selection row (styled like settings)
struct TopShelfSliderRow: View {
    let slider: TopShelfSlider
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            HStack {
                Text(slider.displayTitle)
                    .foregroundStyle(isFocused ? .black : .white)
                    .padding(.leading, 4)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(isFocused ? .black : .secondary)
                        .brightness(isFocused ? 0.4 : 0)
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFocused ? Color.white : Color.clear)
            )
            .scaleEffect(isFocused ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.125), value: isFocused)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets())
        .focused($isFocused)
    }
}

/// Reload button (styled like settings)
struct TopShelfReloadButton: View {
    let action: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.clockwise")
                    .foregroundStyle(isFocused ? .black : .white)
                Text("Reload Sliders from Seerr")
                    .foregroundStyle(isFocused ? .black : .white)
                    .padding(.leading, 4)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFocused ? Color.white : Color.clear)
            )
            .scaleEffect(isFocused ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.125), value: isFocused)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets())
        .focused($isFocused)
    }
}

/// Refresh cache button (styled like settings)
struct TopShelfRefreshCacheButton: View {
    let action: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(isFocused ? .black : .white)
                Text("Refresh TopShelf Cache")
                    .foregroundStyle(isFocused ? .black : .white)
                    .padding(.leading, 4)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFocused ? Color.white : Color.clear)
            )
            .scaleEffect(isFocused ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.125), value: isFocused)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets())
        .focused($isFocused)
    }
}

// MARK: - TopShelfSlider (Simplified)

struct TopShelfSlider {
    let id: Int
    let type: Int
    let order: Int
    let enabled: Bool
    let title: String?
    let data: String?

    var displayTitle: String {
        title ?? defaultTitle(for: type)
    }

    private func defaultTitle(for type: Int) -> String {
        switch type {
        case 1: return "Recently Added"
        case 3: return "Watchlist"
        case 4: return "Trending"
        case 5: return "Popular Movies"
        case 7: return "Upcoming Movies"
        case 9: return "Popular TV"
        case 11: return "Upcoming TV"
        case 13: return "Movie Keyword"
        case 14: return "Movie Genre"
        case 15: return "TV Keyword"
        case 16: return "TV Genre"
        case 17: return "Search"
        case 18: return "Studio"
        case 19: return "Network"
        case 20: return "Movie Streaming"
        case 21: return "TV Streaming"
        case 24: return "Available Movies"
        case 25: return "Available TV"
        case 26: return "Expiring Soon"
        case 27: return "Today's Releases"
        default: return "Content"
        }
    }
}
