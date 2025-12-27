//
//  DiscoverView.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import SwiftUI

/// Discover page - Dynamic slider system matching Seerr web app
/// Fetches slider configuration from server and displays enabled sliders in order
struct DiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @EnvironmentObject var configManager: ConfigManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Group {
                    if viewModel.isLoading && viewModel.allSliders.isEmpty {
                        // Initial loading state
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        // Error state
                        errorView(message: errorMessage)
                    } else if viewModel.enabledSliders.isEmpty {
                        // Empty state (no enabled sliders)
                        emptyView
                    } else {
                        // Display enabled sliders
                        sliderList
                    }
                }
            }
            .task {
                // Load slider configuration when view appears
                await viewModel.fetchSliders()
            }
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
                    .background(Color.Seerr.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
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

    /// Dynamic slider list
    private var sliderList: some View {
        List {
            ForEach(viewModel.enabledSliders) { slider in
                DiscoverSliderRow(slider: slider)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.plain)
    }
}

/// Individual slider row that fetches and displays content for a specific slider type
struct DiscoverSliderRow: View {
    let slider: DiscoverSlider

    @State private var items: [MediaResult] = []
    @State private var calendarItems: [CalendarItem] = []  // For Today's Releases
    @State private var showDeletionRequests = false  // For Deletion Requests slider
    @State private var showMovieGenres = false  // For Movie Genres slider
    @State private var showTVGenres = false  // For TV Genres slider
    @State private var isLoading = false
    @State private var error: String?
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if isLoading {
                // Loading state for this slider
                let _ = print("🔄 Rendering LOADING state for: \(slider.displayTitle)")
                VStack(alignment: .leading, spacing: 20) {
                    Text(slider.displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.leading, 48)

                    HStack {
                        ProgressView()
                            .tint(.white)
                        Text("Loading...")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.leading, 48)
                }
            } else if let error = error {
                // Error state for this slider
                let _ = print("❌ Rendering ERROR state for: \(slider.displayTitle) - \(error)")
                VStack(alignment: .leading, spacing: 12) {
                    Text(slider.displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.leading, 48)

                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading, 48)
                }
            } else if showDeletionRequests {
                // Display Deletion Requests with custom row
                let _ = print("✨ Rendering DELETION REQUESTS slider")
                DeletionRequestsRow()
            } else if showMovieGenres {
                // Display Movie Genres with custom row
                let _ = print("✨ Rendering MOVIE GENRES slider")
                MovieGenresRow(title: slider.displayTitle)
            } else if showTVGenres {
                // Display TV Genres with custom row
                let _ = print("✨ Rendering TV GENRES slider")
                TVGenresRow(title: slider.displayTitle)
            } else if !calendarItems.isEmpty {
                // Display Today's Releases with custom cards
                let _ = print("✨ Rendering TODAY'S RELEASES with \(calendarItems.count) items")
                TodayReleasesRow(title: slider.displayTitle, items: calendarItems)
            } else if !items.isEmpty {
                // Display standard slider with content
                let _ = print("✨ Rendering CONTENT state for: \(slider.displayTitle) with \(items.count) items")
                HorizontalMediaRow(title: slider.displayTitle, items: items)
            } else {
                // DEBUG: Show empty sliders for debugging
                let _ = print("⚠️ Rendering EMPTY state for: \(slider.displayTitle)")
                VStack(alignment: .leading, spacing: 12) {
                    Text(slider.displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.leading, 48)

                    Text("Empty (0 items)")
                        .foregroundColor(.orange)
                        .font(.caption)
                        .padding(.leading, 48)
                }
            }
        }
        .onAppear {
            Task {
                await loadSliderContent()
            }
        }
    }

    /// Load content for this specific slider type
    private func loadSliderContent() async {
        guard !isLoading, !hasLoaded else { return }

        hasLoaded = true
        print("🎬 Loading slider: \(slider.displayTitle) (type: \(slider.type.rawValue))")
        isLoading = true
        error = nil

        do {
            // Special handling for Deletion Requests
            if slider.type == .deletionRequests {
                // Set flag to display DeletionRequestsRow (which manages its own data)
                showDeletionRequests = true
                print("✅ Showing Deletion Requests slider")
                isLoading = false
            }
            // Special handling for Movie Genres
            else if slider.type == .movieGenres {
                // Set flag to display MovieGenresRow (which manages its own data)
                showMovieGenres = true
                print("✅ Showing Movie Genres slider")
                isLoading = false
            }
            // Special handling for TV Genres
            else if slider.type == .tvGenres {
                // Set flag to display TVGenresRow (which manages its own data)
                showTVGenres = true
                print("✅ Showing TV Genres slider")
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
                print("✅ Loaded \(calendarItems.count) calendar items for Today's Releases")
                isLoading = false
            } else {
                // Standard slider content
                items = try await fetchContentForSlider(slider)
                print("✅ Loaded \(items.count) items for: \(slider.displayTitle)")
                print("📊 Items state - isEmpty: \(items.isEmpty), isLoading: false, error: nil")
                isLoading = false
            }
        } catch {
            print("❌ Failed to load \(slider.displayTitle): \(error)")
            self.error = "Failed to load content"
            isLoading = false
        }
    }

    /// Get current date in YYYY-MM-DD format
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    /// Fetch content based on slider type using SliderConfigMapper
    private func fetchContentForSlider(_ slider: DiscoverSlider) async throws -> [MediaResult] {
        let service = SeerrService.shared
        let config = SliderConfigMapper.getConfig(for: slider)

        // Execute the appropriate request based on configuration
        switch config {
        case .discover(let params):
            return try await executeDiscoverRequest(params: params)

        case .media(let filter, let sort, let take):
            let response = try await service.getMediaList(filter: filter, sort: sort, take: take)
            return try await convertMediaInfoToResults(response.results)

        case .request(let filter, let sort, let take):
            let response = try await service.getRequestList(filter: filter, sort: sort, take: take)
            return try convertRequestsToResults(response.results)

        case .calendar(let start, let end):
            let items = try await service.getUpcomingCalendar(startDate: start, endDate: end)
            return try convertCalendarToResults(items)

        case .watchlist:
            // Fetch watchlist items from Seerr database
            let items = try await service.getWatchlist(page: 1)
            return try await fetchWatchlistDetails(items)

        case .genreSlider(let mediaType):
            return try await executeGenreSliderRequest(mediaType: mediaType)

        case .studioContent(let id):
            guard let studioId = Int(id) else {
                throw SeerrError.invalidResponse
            }
            let response = try await service.getMoviesByStudio(studioId: studioId, page: 1)
            return Array(response.results.prefix(20))

        case .networkContent(let id):
            guard let networkId = Int(id) else {
                throw SeerrError.invalidResponse
            }
            let response = try await service.getTVByNetwork(networkId: networkId, page: 1)
            return Array(response.results.prefix(20))

        case .search(let query):
            let response = try await service.search(query: query, page: 1)
            return Array(response.results.prefix(20))

        case .studioList, .networkList, .available:
            // These require special UI, not standard media rows
            throw SeerrError.notImplemented

        case .error(let message):
            // Configuration error - throw to show error state
            throw SeerrError.configurationError(message)
        }
    }

    /// Execute discover request based on parameters
    private func executeDiscoverRequest(params: DiscoverParams) async throws -> [MediaResult] {
        let service = SeerrService.shared

        switch params {
        case .trending:
            let response = try await service.getTrending(page: 1)
            return Array(response.results.prefix(20))

        case .movie(let sortBy, let genre, let keywords, let excludeKeywords, let studio, let primaryReleaseDateGte, let primaryReleaseDateLte, let language, _, _, _, _, let watchRegion, let watchProviders):
            let response = try await service.discoverMovies(
                page: 1,
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
            let mediaResults = response.results.map { MediaResult.movie($0) }
            return Array(mediaResults.prefix(20))

        case .tv(let sortBy, let genre, let keywords, let excludeKeywords, let network, let firstAirDateGte, let firstAirDateLte, let language, let watchRegion, let watchProviders):
            let response = try await service.discoverTV(
                page: 1,
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
            let mediaResults = response.results.map { MediaResult.tv($0) }
            return Array(mediaResults.prefix(20))
        }
    }

    /// Execute genre slider request
    private func executeGenreSliderRequest(mediaType: MediaType) async throws -> [MediaResult] {
        // Genre sliders need to fetch the genre list first, then display all genres
        // Requires a different UI pattern - throw error for now
        throw SeerrError.notImplemented
    }

    /// Convert MediaInfo to MediaResult
    /// Fetches full TMDB details for each item to get poster/backdrop paths
    /// Note: MediaInfo from /api/v1/media doesn't include TMDB metadata
    private func convertMediaInfoToResults(_ mediaInfos: [MediaInfo]) async throws -> [MediaResult] {
        let tmdbService = TMDBService.shared
        var results: [MediaResult] = []

        // Fetch TMDB details for each media item to get posters
        for info in mediaInfos {
            do {
                if info.mediaType == .movie {
                    // Fetch movie details from TMDB
                    let details = try await tmdbService.getMovieDetails(id: info.tmdbId)
                    let movie = MovieResult(
                        id: info.tmdbId,
                        adult: details.adult,
                        backdropPath: details.backdropPath,
                        posterPath: details.posterPath,
                        genreIds: details.genres?.map { $0.id },
                        originalLanguage: details.originalLanguage,
                        originalTitle: details.originalTitle,
                        overview: details.overview,
                        popularity: details.popularity,
                        releaseDate: details.releaseDate,
                        firstAirDate: nil,
                        title: details.title,
                        name: nil,
                        originCountry: nil,
                        originalName: nil,
                        video: details.video ?? false,
                        voteAverage: details.voteAverage,
                        voteCount: details.voteCount,
                        mediaType: "movie",
                        mediaInfo: info  // Include original MediaInfo for status
                    )
                    results.append(.movie(movie))
                } else {
                    // Fetch TV details from TMDB
                    let details = try await tmdbService.getTVDetails(id: info.tmdbId)
                    let tv = TVResult(
                        id: info.tmdbId,
                        backdropPath: details.backdropPath,
                        posterPath: details.posterPath,
                        genreIds: details.genres?.map { $0.id },
                        originalLanguage: details.originalLanguage,
                        originalName: details.originalName,
                        overview: details.overview,
                        popularity: details.popularity,
                        firstAirDate: details.firstAirDate,
                        name: details.name,
                        voteAverage: details.voteAverage,
                        voteCount: details.voteCount,
                        originCountry: details.originCountry,
                        mediaType: "tv",
                        mediaInfo: info  // Include original MediaInfo for status
                    )
                    results.append(.tv(tv))
                }
            } catch {
                // Skip items that fail to load TMDB details
                print("⚠️ Failed to fetch TMDB details for \(info.mediaType) \(info.tmdbId): \(error)")
                continue
            }
        }

        return results
    }

    /// Convert MediaRequest to MediaResult
    private func convertRequestsToResults(_ requests: [MediaRequest]) throws -> [MediaResult] {
        return requests.compactMap { request -> MediaResult? in
            guard let media = request.media else { return nil }

            if media.mediaType == .movie {
                let movie = MovieResult(
                    id: media.tmdbId,
                    adult: false,
                    backdropPath: media.backdropPath,
                    posterPath: media.posterPath,
                    genreIds: media.genres?.map { $0.id },
                    originalLanguage: media.originalLanguage,
                    originalTitle: media.originalTitle,
                    overview: media.overview,
                    popularity: media.popularity,
                    releaseDate: media.releaseDate,
                    firstAirDate: nil,
                    title: media.title,
                    name: nil,
                    originCountry: nil,
                    originalName: nil,
                    video: false,
                    voteAverage: media.voteAverage,
                    voteCount: media.voteCount,
                    mediaType: "movie",
                    mediaInfo: nil
                )
                return MediaResult.movie(movie)
            } else {
                let tv = TVResult(
                    id: media.tmdbId,
                    backdropPath: media.backdropPath,
                    posterPath: media.posterPath,
                    genreIds: media.genres?.map { $0.id },
                    originalLanguage: media.originalLanguage,
                    originalName: media.originalTitle,
                    overview: media.overview,
                    popularity: media.popularity,
                    firstAirDate: media.firstAirDate,
                    name: media.title ?? "",
                    voteAverage: media.voteAverage,
                    voteCount: media.voteCount,
                    originCountry: media.originCountry,
                    mediaType: "tv",
                    mediaInfo: nil
                )
                return MediaResult.tv(tv)
            }
        }
    }

    /// Convert CalendarItem to MediaResult
    private func convertCalendarToResults(_ items: [CalendarItem]) throws -> [MediaResult] {
        return items.compactMap { item in
            if item.type == "movie" {
                let movie = MovieResult(
                    id: item.tmdbId,
                    adult: false,
                    backdropPath: item.backdropPath,
                    posterPath: item.posterPath,
                    genreIds: nil,
                    originalLanguage: "en",
                    originalTitle: item.title,
                    overview: item.overview,
                    popularity: 0,
                    releaseDate: item.releaseDate,
                    firstAirDate: nil,
                    title: item.title,
                    name: nil,
                    originCountry: nil,
                    originalName: nil,
                    video: false,
                    voteAverage: 0,
                    voteCount: 0,
                    mediaType: "movie",
                    mediaInfo: nil
                )
                return MediaResult.movie(movie)
            } else {
                let tv = TVResult(
                    id: item.tmdbId,
                    backdropPath: item.backdropPath,
                    posterPath: item.posterPath,
                    genreIds: nil,
                    originalLanguage: "en",
                    originalName: item.title,
                    overview: item.overview,
                    popularity: 0,
                    firstAirDate: item.releaseDate,
                    name: item.title,
                    voteAverage: 0,
                    voteCount: 0,
                    originCountry: nil,
                    mediaType: "tv",
                    mediaInfo: nil
                )
                return MediaResult.tv(tv)
            }
        }
    }

    /// Fetch full details for watchlist items
    /// Watchlist API only returns basic info (title, tmdbId) so we need to fetch full details
    /// Hybrid approach: TMDB for visual metadata + Seerr for availability status
    private func fetchWatchlistDetails(_ items: [WatchlistItem]) async throws -> [MediaResult] {
        let seerrService = SeerrService.shared
        let tmdbService = TMDBService.shared
        var results: [MediaResult] = []

        // Fetch details for each item (limit to 20 items to avoid too many requests)
        for item in items.prefix(20) {
            guard let tmdbId = item.tmdbId else { continue }

            do {
                if item.mediaType == "movie" {
                    // Fetch from both APIs in parallel
                    async let tmdbDetails = tmdbService.getMovieDetails(id: tmdbId)
                    async let seerrDetails = try? seerrService.getMovieDetails(id: tmdbId)

                    let (tmdb, seerr) = await (tmdbDetails, seerrDetails)

                    print("🎬 Movie details for \(item.title): tmdbPoster=\(tmdb.posterPath ?? "nil"), status=\(seerr?.mediaInfo?.status.rawValue ?? 0)")

                    let movie = MovieResult(
                        id: tmdb.id,
                        adult: tmdb.adult,
                        backdropPath: tmdb.backdropPath,
                        posterPath: tmdb.posterPath,  // Use TMDB posterPath
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
                        video: tmdb.video ?? false,
                        voteAverage: tmdb.voteAverage,
                        voteCount: tmdb.voteCount,
                        mediaType: "movie",
                        mediaInfo: seerr?.mediaInfo  // Use Seerr mediaInfo with status
                    )
                    results.append(.movie(movie))
                } else {
                    // Fetch from both APIs in parallel
                    async let tmdbDetails = tmdbService.getTVDetails(id: tmdbId)
                    async let seerrDetails = try? seerrService.getTVDetails(id: tmdbId)

                    let (tmdb, seerr) = await (tmdbDetails, seerrDetails)

                    print("📺 TV details for \(item.title): tmdbPoster=\(tmdb.posterPath ?? "nil"), status=\(seerr?.mediaInfo?.status.rawValue ?? 0)")

                    let tv = TVResult(
                        id: tmdb.id,
                        backdropPath: tmdb.backdropPath,
                        posterPath: tmdb.posterPath,  // Use TMDB posterPath
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
                        mediaInfo: seerr?.mediaInfo  // Use Seerr mediaInfo with status
                    )
                    results.append(.tv(tv))
                }
            } catch {
                // Skip items that fail to load details
                print("⚠️ Failed to fetch details for watchlist item \(tmdbId): \(error)")
                continue
            }
        }

        return results
    }
}

#Preview {
    DiscoverView()
        .environmentObject(ConfigManager())
}
