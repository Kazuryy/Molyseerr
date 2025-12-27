//
//  TMDBService.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import Foundation

/// Direct TMDB API service
/// Uses the same hardcoded API key as Seerr (from server/api/themoviedb/index.ts:138)
/// This bypasses Seerr server for faster and more reliable TMDB metadata fetching
@MainActor
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
