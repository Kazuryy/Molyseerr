//
//  TMDBService.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import Foundation
import Combine

/// Direct TMDB API service
/// Uses the same hardcoded API key as Seerr (from server/api/themoviedb/index.ts:138)
/// This bypasses Seerr server for faster and more reliable TMDB metadata fetching
/// Note: Not marked @MainActor to allow usage in TopShelf extension
class TMDBService {
    static let shared = TMDBService()

    // TMDB API key from Seerr codebase (public, hardcoded in their source)
    // Source: seerr/server/api/themoviedb/index.ts line 138
    private let apiKey = "431a8708161bcd1f1fbe7536137e61ed"
    private let baseURL = "https://api.themoviedb.org/3"

    private init() {}

    // MARK: - Movie Endpoints

    /// Get movie details directly from TMDB
    /// - Parameters:
    ///   - id: TMDB movie ID
    ///   - language: Language code (default: "en")
    /// - Returns: Movie details with all TMDB metadata
    func getMovieDetails(id: Int, language: String = "en") async throws -> TMDBMovieDetails {
        let endpoint = "\(baseURL)/movie/\(id)"
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: language)
        ]

        guard let url = components.url else {
            throw TMDBError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw TMDBError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(TMDBMovieDetails.self, from: data)
    }

    // MARK: - TV Endpoints

    /// Get TV show details directly from TMDB
    /// - Parameters:
    ///   - id: TMDB TV show ID
    ///   - language: Language code (default: "en")
    /// - Returns: TV show details with all TMDB metadata
    func getTVDetails(id: Int, language: String = "en") async throws -> TMDBTVDetails {
        let endpoint = "\(baseURL)/tv/\(id)"
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: language)
        ]

        guard let url = components.url else {
            throw TMDBError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw TMDBError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(TMDBTVDetails.self, from: data)
    }

    /// Get season details with episodes directly from TMDB
    /// - Parameters:
    ///   - tvID: TMDB TV show ID
    ///   - seasonNumber: Season number
    ///   - language: Language code (default: "en")
    /// - Returns: Array of TMDB episodes for the season
    func fetchSeasonDetails(tvID: Int, seasonNumber: Int, language: String = "en") async throws -> [TMDBEpisode] {
        let endpoint = "\(baseURL)/tv/\(tvID)/season/\(seasonNumber)"
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: language)
        ]

        guard let url = components.url else {
            throw TMDBError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw TMDBError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let seasonDetails = try decoder.decode(TMDBSeasonDetails.self, from: data)
        return seasonDetails.episodes
    }

    // MARK: - Images Endpoints

    /// Get movie images (logos, posters, backdrops)
    /// - Parameters:
    ///   - id: TMDB movie ID
    ///   - language: Language code (default: "en")
    /// - Returns: Movie images including logos
    func getMovieImages(id: Int, language: String = "en") async throws -> TMDBImages {
        let endpoint = "\(baseURL)/movie/\(id)/images"
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "include_image_language", value: "\(language),null")
        ]

        guard let url = components.url else {
            throw TMDBError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw TMDBError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(TMDBImages.self, from: data)
    }

    /// Get TV show images (logos, posters, backdrops)
    /// - Parameters:
    ///   - id: TMDB TV show ID
    ///   - language: Language code (default: "en")
    /// - Returns: TV show images including logos
    func getTVImages(id: Int, language: String = "en") async throws -> TMDBImages {
        let endpoint = "\(baseURL)/tv/\(id)/images"
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "include_image_language", value: "\(language),null")
        ]

        guard let url = components.url else {
            throw TMDBError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw TMDBError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(TMDBImages.self, from: data)
    }

    // MARK: - Trending Endpoints

    /// Get trending movies and TV shows for the week
    /// - Parameters:
    ///   - mediaType: "all", "movie", or "tv"
    ///   - timeWindow: "day" or "week"
    ///   - page: Page number (default: 1)
    ///   - language: Language code (default: "en")
    /// - Returns: Paginated response with trending items
    func getTrending(mediaType: String = "all", timeWindow: String = "week", page: Int = 1, language: String = "en") async throws -> TMDBPaginatedResponse {
        let endpoint = "\(baseURL)/trending/\(mediaType)/\(timeWindow)"
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "page", value: String(page))
        ]

        guard let url = components.url else {
            throw TMDBError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw TMDBError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(TMDBPaginatedResponse.self, from: data)
    }
}

// MARK: - TMDB Models

/// TMDB Movie Details
/// Simplified model with only the fields we need
struct TMDBMovieDetails: Codable {
    let id: Int
    let title: String
    let originalTitle: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double?
    let voteCount: Int?
    let popularity: Double?
    let originalLanguage: String
    let adult: Bool
    let video: Bool?
    let genres: [TMDBGenre]?
}

/// TMDB TV Show Details
/// Simplified model with only the fields we need
struct TMDBTVDetails: Codable {
    let id: Int
    let name: String
    let originalName: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let voteCount: Int?
    let popularity: Double?
    let originalLanguage: String
    let originCountry: [String]?
    let genres: [TMDBGenre]?
}

/// TMDB Genre
struct TMDBGenre: Codable {
    let id: Int
    let name: String
}

/// TMDB Images Response
struct TMDBImages: Codable {
    let id: Int
    let backdrops: [TMDBImageInfo]?
    let logos: [TMDBImageInfo]?
    let posters: [TMDBImageInfo]?
}

/// TMDB Image Info
struct TMDBImageInfo: Codable {
    let aspectRatio: Double
    let height: Int
    let width: Int
    let filePath: String
    let voteAverage: Double?
    let voteCount: Int?
    let iso6391: String?

    /// Get the full URL for this image
    /// - Parameter size: Image size (w45, w92, w154, w185, w342, w500, w780, w1280, original)
    /// - Returns: Full TMDB image URL
    func imageURL(size: String = "w500") -> URL? {
        return URL(string: "https://image.tmdb.org/t/p/\(size)\(filePath)")
    }
}

/// TMDB Episode
struct TMDBEpisode: Codable {
    let id: Int
    let name: String?
    let airDate: String?
    let episodeNumber: Int?
    let overview: String?
    let productionCode: String?
    let seasonNumber: Int?
    let showId: Int?
    let stillPath: String?
    let voteAverage: Double?
    let voteCount: Int?
}

/// TMDB Season Details (with episodes)
struct TMDBSeasonDetails: Codable {
    let id: Int
    let name: String?
    let seasonNumber: Int?
    let episodes: [TMDBEpisode]
}

/// TMDB Paginated Response (for trending, discover, etc.)
struct TMDBPaginatedResponse: Codable {
    let page: Int
    let results: [TMDBMediaItem]
    let totalPages: Int
    let totalResults: Int
}

/// TMDB Media Item (movie or TV show)
struct TMDBMediaItem: Codable {
    let id: Int
    let mediaType: String?
    let title: String?
    let name: String?
    let originalTitle: String?
    let originalName: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let voteCount: Int?
    let popularity: Double?
    let adult: Bool?

    /// Computed property to get the display title
    var displayTitle: String {
        return title ?? name ?? originalTitle ?? originalName ?? "Unknown"
    }

    /// Computed property to check if this is a movie
    var isMovie: Bool {
        return mediaType == "movie" || title != nil
    }
}

// MARK: - Errors

enum TMDBError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid TMDB URL"
        case .invalidResponse:
            return "Invalid response from TMDB"
        case .httpError(let code):
            return "TMDB HTTP error: \(code)"
        }
    }
}
