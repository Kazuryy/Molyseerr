//
//  DiscoverContentService.swift
//  Molyseerr
//
//  Created by Claude on 03/01/2026.
//

import Foundation

/// Shared service for fetching Discover slider content
/// Used by both DiscoverSliderRow and background prefetching
actor DiscoverContentService {
    static let shared = DiscoverContentService()

    private init() {}

    /// Fetch content for a discover slider
    func fetchContentForSlider(_ slider: DiscoverSlider) async throws -> [MediaResult] {
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

        case .available(let mediaType):
            let response = try await service.getAvailableMedia(
                type: mediaType.rawValue,
                page: 1,
                sortBy: "mediaAddedAt"
            )
            return Array(response.results.prefix(20))

        case .studioList, .networkList:
            // These require special UI, not standard media rows
            throw SeerrError.notImplemented

        case .error(let message):
            // Configuration error - throw to show error state
            throw SeerrError.configurationError(message)
        }
    }

    // MARK: - Private Helper Methods

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
    /// Optimized: Parallelizes TMDB API calls using TaskGroup for better performance
    private func convertMediaInfoToResults(_ mediaInfos: [MediaInfo]) async throws -> [MediaResult] {
        let tmdbService = TMDBService.shared

        // Parallelize TMDB API calls using TaskGroup
        let results = await withTaskGroup(of: MediaResult?.self) { group in
            // Add tasks for each media info
            for info in mediaInfos {
                group.addTask {
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
                            return .movie(movie)
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
                            return .tv(tv)
                        }
                    } catch {
                        // Skip items that fail to load TMDB details
                        return nil
                    }
                }
            }

            // Collect results
            var collected: [MediaResult] = []
            for await result in group {
                if let result = result {
                    collected.append(result)
                }
            }
            return collected
        }

        return results
    }

    /// Convert MediaRequest to MediaResult
    private func convertRequestsToResults(_ requests: [MediaRequest]) throws -> [MediaResult] {
        return requests.compactMap { request -> MediaResult? in
            guard let media = request.media else { return nil }

            if media.mediaType == .movie || media.mediaType == nil {  // Default to movie if nil
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

                    let (tmdb, seerr) = try await (tmdbDetails, seerrDetails)

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

                    let (tmdb, seerr) = try await (tmdbDetails, seerrDetails)

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
                continue
            }
        }

        return results
    }
}
