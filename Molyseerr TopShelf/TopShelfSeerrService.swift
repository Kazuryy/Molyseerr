//
//  TopShelfSeerrService.swift
//  Molyseerr TopShelf
//
//  Created by Claude on 02/01/2026.
//

import Foundation

/// Lightweight service for TopShelf extension
/// Calls TMDB API directly (no Seerr authentication needed)
/// Uses the same hardcoded TMDB API key as the main app
class TopShelfSeerrService {

    // MARK: - Singleton

    static let shared = TopShelfSeerrService()

    // MARK: - Properties

    // TMDB API key from Seerr codebase (public, hardcoded in their source)
    // Source: seerr/server/api/themoviedb/index.ts line 138
    private let tmdbAPIKey = "431a8708161bcd1f1fbe7536137e61ed"
    private let tmdbBaseURL = "https://api.themoviedb.org/3"

    // MARK: - Configuration

    /// Configure service (kept for compatibility but not needed for TMDB direct)
    func configure(baseURL: String?, apiKey: String?) {
        // Not needed - we use TMDB directly
    }

    /// Always configured since we use TMDB directly
    var isConfigured: Bool {
        return true
    }

    // MARK: - API Calls

    /// Note: This method is not used in TopShelf extension
    /// The main app fetches sliders from Seerr and stores them in UserDefaults
    func getDiscoverSliders() async throws -> [TopShelfSlider] {
        // Not implemented - main app handles this
        throw SeerrError.notImplemented
    }

    /// Fetch media items for a specific slider from cache
    /// The main app pre-fetches content from Seerr and stores it in UserDefaults
    func getSliderContent(slider: TopShelfSliderConfig, limit: Int = 10) async throws -> [TopShelfMediaItem] {
        print("📖 Reading cached content for slider \(slider.id): \(slider.title)")

        // Read from cache
        let cache = TopShelfSettings.shared.sliderContentCache
        guard let items = cache["\(slider.id)"] else {
            print("⚠️ No cached content found for slider \(slider.id)")
            throw SeerrError.noCachedContent
        }

        print("✅ Found \(items.count) cached items")

        // Convert cache to TopShelfMediaItem
        let mediaItems = items.prefix(limit).compactMap { dict -> TopShelfMediaItem? in
            guard let idString = dict["id"],
                  let id = Int(idString),
                  let title = dict["title"],
                  let mediaType = dict["mediaType"] else {
                return nil
            }

            return TopShelfMediaItem(
                id: id,
                title: title,
                posterPath: dict["posterPath"],
                backdropPath: dict["backdropPath"],
                mediaType: mediaType,
                overview: dict["overview"],
                logoPath: dict["logoPath"]
            )
        }

        return Array(mediaItems)
    }

    // MARK: - Private Helpers

    private func getEndpoint(for sliderType: Int) -> String {
        switch sliderType {
        case 1: return "/api/v1/media" // recentlyAdded
        case 3: return "/api/v1/discover/watchlist" // watchlist
        case 4: return "/api/v1/discover/trending" // trending
        case 5: return "/api/v1/discover/movies" // popularMovies
        case 7: return "/api/v1/discover/movies" // upcomingMovies
        case 9: return "/api/v1/discover/tv" // popularTV
        case 11: return "/api/v1/discover/tv" // upcomingTV
        case 13, 14, 17, 18, 20: return "/api/v1/discover/movies" // TMDB movie variants
        case 15, 16, 19, 21: return "/api/v1/discover/tv" // TMDB TV variants
        case 24: return "/api/v1/available/movies" // availableMovies
        case 25: return "/api/v1/available/movies" // availableTV
        case 26: return "/api/v1/media" // expiringSoon
        case 27: return "/api/v1/calendar/upcoming" // todaysReleases
        default: return "/api/v1/discover/trending" // fallback
        }
    }

    private func getQueryParams(for sliderType: Int, limit: Int) -> String {
        var params: [String: String] = ["page": "1"]

        switch sliderType {
        case 1: // recentlyAdded
            params["filter"] = "allavailable"
            params["sort"] = "mediaAdded"
            params["take"] = "\(limit)"
        case 3: // watchlist
            break // no special params
        case 4: // trending
            break // no special params
        case 5: // popularMovies
            params["sortBy"] = "popularity.desc"
        case 7: // upcomingMovies
            let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
            params["primaryReleaseDateGte"] = String(today)
            params["sortBy"] = "popularity.desc"
        case 9: // popularTV
            params["sortBy"] = "popularity.desc"
        case 11: // upcomingTV
            let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
            params["firstAirDateGte"] = String(today)
            params["sortBy"] = "popularity.desc"
        case 24: // availableMovies
            params["type"] = "movie"
        case 25: // availableTV
            params["type"] = "tv"
        case 26: // expiringSoon
            params["filter"] = "expiringsoon"
            params["take"] = "\(limit)"
        case 27: // todaysReleases
            let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
            params["start"] = String(today)
            params["end"] = String(today)
        default:
            break
        }

        return params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
    }

    private func decodeMediaResponse(data: Data, sliderType: Int) throws -> [TopShelfMediaItem] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Different response structures based on endpoint
        switch sliderType {
        case 1, 26: // media endpoint
            let response = try decoder.decode(MediaListResponse.self, from: data)
            return response.results.compactMap { TopShelfMediaItem(from: $0) }
        case 27: // calendar endpoint
            let response = try decoder.decode(CalendarResponse.self, from: data)
            return response.items.compactMap { TopShelfMediaItem(from: $0) }
        default: // discover endpoints
            let response = try decoder.decode(PaginatedMediaResponse.self, from: data)
            return response.results.compactMap { TopShelfMediaItem(from: $0) }
        }
    }

    // MARK: - Errors

    enum SeerrError: Error {
        case notConfigured
        case notImplemented
        case noCachedContent
        case invalidURL
        case invalidResponse
        case httpError(Int)
        case decodingError
    }
}

// MARK: - Simplified Models

/// Simplified slider model for TopShelf
struct TopShelfSlider: Codable {
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

/// Simplified media item model for TopShelf
struct TopShelfMediaItem {
    let id: Int
    let title: String
    let posterPath: String?
    let backdropPath: String?
    let mediaType: String // "movie" or "tv"
    let overview: String?
    let logoPath: String? // TV show/movie logo

    init(id: Int, title: String, posterPath: String?, backdropPath: String?, mediaType: String, overview: String?, logoPath: String? = nil) {
        self.id = id
        self.title = title
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.mediaType = mediaType
        self.overview = overview
        self.logoPath = logoPath
    }

    init?(from mediaResult: MediaResult) {
        guard let id = mediaResult.id else { return nil }
        self.id = id
        self.title = mediaResult.title ?? mediaResult.name ?? ""
        self.posterPath = mediaResult.posterPath
        self.backdropPath = mediaResult.backdropPath
        self.mediaType = mediaResult.mediaType ?? "movie"
        self.overview = mediaResult.overview
        self.logoPath = nil // Not available in MediaResult
    }

    init?(from calendarItem: CalendarItem) {
        self.id = calendarItem.tmdbId
        self.title = calendarItem.title
        self.posterPath = calendarItem.posterPath
        self.backdropPath = calendarItem.backdropPath
        self.mediaType = calendarItem.type
        self.overview = nil
        self.logoPath = nil // Not available in CalendarItem
    }
}

// MARK: - Response Models

struct PaginatedMediaResponse: Codable {
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let results: [MediaResult]
}

struct MediaListResponse: Codable {
    let pageInfo: PageInfo
    let results: [MediaResult]

    struct PageInfo: Codable {
        let pages: Int
        let pageSize: Int
        let results: Int
        let page: Int
    }
}

struct CalendarResponse: Codable {
    let items: [CalendarItem]
}

struct MediaResult: Codable {
    let id: Int?
    let tmdbId: Int?
    let title: String?
    let name: String?
    let posterPath: String?
    let backdropPath: String?
    let mediaType: String?
    let overview: String?
}

struct CalendarItem: Codable {
    let type: String
    let tmdbId: Int
    let title: String
    let posterPath: String?
    let backdropPath: String?
}
