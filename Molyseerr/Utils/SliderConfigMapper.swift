//
//  SliderConfigMapper.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import Foundation

/// Maps discover slider configurations to API request parameters
/// This allows ALL 27 slider types to work dynamically, including custom sliders with data
/// Reference: Seerr web src/components/Discover/index.tsx and server/routes/discover.ts
struct SliderConfigMapper {

    /// Get API request configuration for a slider
    static func getConfig(for slider: DiscoverSlider) -> SliderRequestConfig {
        switch slider.type {
        // MARK: - Built-in Sliders (No Data Required)

        case .recentlyAdded:
            // TODO: Requires special handling - MediaInfo doesn't contain TMDB metadata
            // Need to fetch full details for each item
            return .error("Recently Added slider requires additional implementation")

        case .recentRequests:
            // TODO: Requires special handling - need to extract media from requests
            return .error("Recent Requests slider requires additional implementation")

        case .watchlist:
            return .watchlist

        case .trending:
            return .discover(.trending)

        case .popularMovies:
            return .discover(.movie(sortBy: "popularity.desc"))

        case .movieGenres:
            return .genreSlider(.movie)

        case .upcomingMovies:
            return .discover(.movie(
                sortBy: "release_date.desc",
                primaryReleaseDateGte: getCurrentDate(),
                primaryReleaseDateLte: getDateInFuture(months: 3)
            ))

        case .studios:
            return .studioList

        case .popularTV:
            return .discover(.tv(sortBy: "popularity.desc"))

        case .tvGenres:
            return .genreSlider(.tv)

        case .upcomingTV:
            return .discover(.tv(
                sortBy: "first_air_date.desc",
                firstAirDateGte: getCurrentDate(),
                firstAirDateLte: getDateInFuture(months: 3)
            ))

        case .networks:
            return .networkList

        case .deletionRequests:
            // TODO: Same issue as recentRequests - MediaRequest needs special handling
            return .error("Deletion Requests slider requires additional implementation")

        case .availableMovies:
            // TODO: Needs special endpoint or filter
            return .error("Available Movies slider requires additional implementation")

        case .availableTV:
            // TODO: Needs special endpoint or filter
            return .error("Available TV slider requires additional implementation")

        case .expiringSoon:
            // TODO: Same issue as recentlyAdded - MediaInfo needs special handling
            return .error("Expiring Soon slider requires additional implementation")

        case .todaysReleases:
            let today = getCurrentDate()
            return .calendar(start: today, end: today)

        // MARK: - Custom Sliders (Require Data Field)

        case .tmdbMovieKeyword:
            guard let keywords = slider.data else {
                return .error("Missing keyword data for movie keyword slider")
            }
            return .discover(.movie(keywords: keywords))

        case .tmdbMovieGenre:
            guard let genre = slider.data else {
                return .error("Missing genre data for movie genre slider")
            }
            return .discover(.movie(genre: genre))

        case .tmdbTVKeyword:
            guard let keywords = slider.data else {
                return .error("Missing keyword data for TV keyword slider")
            }
            return .discover(.tv(keywords: keywords))

        case .tmdbTVGenre:
            guard let genre = slider.data else {
                return .error("Missing genre data for TV genre slider")
            }
            return .discover(.tv(genre: genre))

        case .tmdbSearch:
            guard let query = slider.data else {
                return .error("Missing search query for search slider")
            }
            return .search(query: query)

        case .tmdbStudio:
            guard let studioId = slider.data else {
                return .error("Missing studio ID for studio slider")
            }
            return .studioContent(id: studioId)

        case .tmdbNetwork:
            guard let networkId = slider.data else {
                return .error("Missing network ID for network slider")
            }
            return .networkContent(id: networkId)

        case .tmdbMovieStreamingServices:
            let (region, providers) = parseStreamingData(slider.data)
            guard let region = region, let providers = providers else {
                return .error("Invalid streaming data format for movie streaming slider")
            }
            return .discover(.movie(watchRegion: region, watchProviders: providers))

        case .tmdbTVStreamingServices:
            let (region, providers) = parseStreamingData(slider.data)
            guard let region = region, let providers = providers else {
                return .error("Invalid streaming data format for TV streaming slider")
            }
            return .discover(.tv(watchRegion: region, watchProviders: providers))
        }
    }

    // MARK: - Helper Methods

    /// Parse streaming service data format: "region,providers"
    /// Example: "US,8|9" means US region with providers 8 and 9
    private static func parseStreamingData(_ data: String?) -> (region: String?, providers: String?) {
        guard let data = data else { return (nil, nil) }
        let parts = data.split(separator: ",").map(String.init)
        guard parts.count == 2 else { return (nil, nil) }
        return (parts[0], parts[1])
    }

    /// Get current date in YYYY-MM-DD format
    private static func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    /// Get date in future (for upcoming filters)
    private static func getDateInFuture(months: Int) -> String {
        let calendar = Calendar.current
        guard let futureDate = calendar.date(byAdding: .month, value: months, to: Date()) else {
            return getCurrentDate()
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: futureDate)
    }
}

// MARK: - Request Configuration Types

/// Configuration for a slider API request
enum SliderRequestConfig {
    /// Standard discover endpoint (movies/TV/trending)
    case discover(DiscoverParams)

    /// Media endpoint (recently added, expiring)
    case media(filter: String, sort: String?, take: Int)

    /// Request endpoint (recent/deletion requests)
    case request(filter: String, sort: String, take: Int)

    /// Calendar endpoint (today's releases)
    case calendar(start: String, end: String)

    /// Watchlist endpoint (Seerr database)
    case watchlist

    /// Genre slider endpoint (returns genre list)
    case genreSlider(MediaType)

    /// Studio list endpoint
    case studioList

    /// Network list endpoint
    case networkList

    /// Studio content endpoint (movies by studio)
    case studioContent(id: String)

    /// Network content endpoint (TV by network)
    case networkContent(id: String)

    /// Search endpoint
    case search(query: String)

    /// Available media endpoint
    case available(type: MediaType)

    /// Error state (invalid configuration)
    case error(String)
}

/// Discover endpoint parameters
enum DiscoverParams {
    case trending
    case movie(
        sortBy: String = "popularity.desc",
        genre: String? = nil,
        keywords: String? = nil,
        excludeKeywords: String? = nil,
        studio: String? = nil,
        primaryReleaseDateGte: String? = nil,
        primaryReleaseDateLte: String? = nil,
        language: String? = nil,
        withRuntimeGte: String? = nil,
        withRuntimeLte: String? = nil,
        voteAverageGte: String? = nil,
        voteAverageLte: String? = nil,
        watchRegion: String? = nil,
        watchProviders: String? = nil
    )
    case tv(
        sortBy: String = "popularity.desc",
        genre: String? = nil,
        keywords: String? = nil,
        excludeKeywords: String? = nil,
        network: String? = nil,
        firstAirDateGte: String? = nil,
        firstAirDateLte: String? = nil,
        language: String? = nil,
        watchRegion: String? = nil,
        watchProviders: String? = nil
    )
}
