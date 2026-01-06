//
//  DiscoverSlider.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import Foundation

/// Discover slider configuration model
/// Matches Seerr API: GET /api/v1/settings/discover
struct DiscoverSlider: Codable, Identifiable {
    let id: Int
    let type: SliderType
    let order: Int
    let isBuiltIn: Bool
    let enabled: Bool
    let title: String?
    let data: String?
    let createdAt: String
    let updatedAt: String

    /// Display title - uses custom title if set, otherwise default for type
    var displayTitle: String {
        title ?? type.defaultTitle
    }
}

/// Slider types supported by Seerr
/// Reference: seerr/server/constants/discover.ts
enum SliderType: Int, Codable {
    case recentlyAdded = 1
    case recentRequests = 2
    case watchlist = 3
    case trending = 4
    case popularMovies = 5
    case movieGenres = 6
    case upcomingMovies = 7
    case studios = 8
    case popularTV = 9
    case tvGenres = 10
    case upcomingTV = 11
    case networks = 12
    case tmdbMovieKeyword = 13
    case tmdbMovieGenre = 14
    case tmdbTVKeyword = 15
    case tmdbTVGenre = 16
    case tmdbSearch = 17
    case tmdbStudio = 18
    case tmdbNetwork = 19
    case tmdbMovieStreamingServices = 20
    case tmdbTVStreamingServices = 21
    case deletionRequests = 22
    case availableMovies = 24
    case availableTV = 25
    case expiringSoon = 26
    case todaysReleases = 27

    /// Default title for each slider type
    var defaultTitle: String {
        switch self {
        case .recentlyAdded: return "Recently Added"
        case .recentRequests: return "Recent Requests"
        case .watchlist: return "Watchlist"
        case .trending: return "Trending"
        case .popularMovies: return "Popular Movies"
        case .movieGenres: return "Movie Genres"
        case .upcomingMovies: return "Upcoming Movies"
        case .studios: return "Studios"
        case .popularTV: return "Popular TV Shows"
        case .tvGenres: return "TV Genres"
        case .upcomingTV: return "Upcoming TV Shows"
        case .networks: return "Networks"
        case .tmdbMovieKeyword: return "Movie Keyword"
        case .tmdbMovieGenre: return "Movie Genre"
        case .tmdbTVKeyword: return "TV Keyword"
        case .tmdbTVGenre: return "TV Genre"
        case .tmdbSearch: return "Search"
        case .tmdbStudio: return "Studio"
        case .tmdbNetwork: return "Network"
        case .tmdbMovieStreamingServices: return "Movie Streaming"
        case .tmdbTVStreamingServices: return "TV Streaming"
        case .deletionRequests: return "Deletion Requests"
        case .availableMovies: return "Available Movies"
        case .availableTV: return "Available TV"
        case .expiringSoon: return "Expiring Soon"
        case .todaysReleases: return "Today's Releases"
        }
    }

    /// API endpoint URL component for fetching slider data
    var apiEndpoint: String {
        switch self {
        case .trending:
            return "/api/v1/discover/trending"
        case .popularMovies, .upcomingMovies, .tmdbMovieKeyword, .tmdbMovieGenre, .tmdbSearch, .tmdbMovieStreamingServices, .availableMovies:
            return "/api/v1/discover/movies"
        case .popularTV, .upcomingTV, .tmdbTVKeyword, .tmdbTVGenre, .tmdbTVStreamingServices, .availableTV:
            return "/api/v1/discover/tv"
        case .movieGenres:
            return "/api/v1/discover/genreslider/movie"
        case .tvGenres:
            return "/api/v1/discover/genreslider/tv"
        case .watchlist:
            return "/api/v1/discover/watchlist"
        case .recentlyAdded, .recentRequests, .deletionRequests, .expiringSoon, .todaysReleases:
            return "/api/v1/discover/movies" // TODO: Verify correct endpoints
        case .studios:
            return "/api/v1/discover/movies" // TODO: Add studio filtering
        case .networks:
            return "/api/v1/discover/tv" // TODO: Add network filtering
        case .tmdbStudio:
            return "/api/v1/discover/movies" // TODO: Add studio filtering
        case .tmdbNetwork:
            return "/api/v1/discover/tv" // TODO: Add network filtering
        }
    }

    /// Check if this slider type is a Docker-specific feature
    var isDockerFeature: Bool {
        switch self {
        case .todaysReleases:
            return true // Calendar feature
        case .availableMovies, .availableTV:
            return true // Available media feature
        case .deletionRequests, .expiringSoon:
            return true // Deletion requests/voting feature
        default:
            return false
        }
    }

    /// Check if this slider should be shown based on feature flags
    func isAvailable(with flags: FeatureFlags) -> Bool {
        switch self {
        case .todaysReleases:
            return flags.calendarEnabled
        case .availableMovies, .availableTV:
            return flags.availableMediaEnabled
        case .deletionRequests, .expiringSoon:
            return flags.deletionRequestsEnabled
        default:
            return true // Standard sliders are always available
        }
    }
}

// MARK: - DiscoverSlider Extensions

extension DiscoverSlider {
    /// Check if this slider should be shown based on feature flags
    func isAvailable(with flags: FeatureFlags) -> Bool {
        type.isAvailable(with: flags)
    }
}

extension Array where Element == DiscoverSlider {
    /// Filter sliders based on feature flags
    func filterByFeatureFlags(_ flags: FeatureFlags) -> [DiscoverSlider] {
        filter { $0.isAvailable(with: flags) }
    }
}
