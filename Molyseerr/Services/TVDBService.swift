//
//  TVDBService.swift
//  Molyseerr
//
//  Created by Claude on 30/12/2025.
//

import Foundation

/// TVDB API service for fetching episode data
/// Uses TVDB API v4
@MainActor
class TVDBService {
    static let shared = TVDBService()

    // TVDB API key - This is Seerr's public key from their codebase
    // Source: seerr/server/api/tvdb/index.ts:114
    private let apiKey = "d00d9ecb-a9d0-4860-958a-74b14a041405"
    private let baseURL = "https://api4.thetvdb.com/v4"

    private var authToken: String?
    private var tokenExpiry: Date?

    private init() {}

    // MARK: - Language Conversion

    /// Convert TMDB language code (ISO 639-1) to TVDB language code (ISO 639-3)
    /// Based on Seerr's convertTMDBToTVDB function
    /// Source: seerr/server/api/tvdb/interfaces.ts
    private func convertTMDBToTVDB(_ tmdbCode: String) -> String {
        let mapping: [String: String] = [
            "ar": "ara",      // Arabic
            "cs": "ces",      // Czech
            "da": "dan",      // Danish
            "de": "deu",      // German
            "el": "ell",      // Greek
            "en": "eng",      // English
            "es": "spa",      // Spanish
            "fi": "fin",      // Finnish
            "fr": "fra",      // French
            "he": "heb",      // Hebrew
            "hr": "hrv",      // Croatian
            "hu": "hun",      // Hungarian
            "it": "ita",      // Italian
            "ja": "jpn",      // Japanese
            "ko": "kor",      // Korean
            "nl": "nld",      // Dutch
            "no": "nor",      // Norwegian
            "pl": "pol",      // Polish
            "pt": "por",      // Portuguese
            "pt-BR": "pt",    // Portuguese (Brazil)
            "ro": "ron",      // Romanian
            "ru": "rus",      // Russian
            "sk": "slk",      // Slovak
            "sv": "swe",      // Swedish
            "th": "tha",      // Thai
            "tr": "tur",      // Turkish
            "uk": "ukr",      // Ukrainian
            "zh": "zho",      // Chinese
            "zh-CN": "zho",   // Chinese (Simplified)
            "zh-TW": "zho"    // Chinese (Traditional)
        ]
        return mapping[tmdbCode] ?? "eng"  // Default to English
    }

    // MARK: - Authentication

    /// Authenticate with TVDB API and get a token
    private func authenticate() async throws {
        // Check if we have a valid token
        if let _ = authToken, let expiry = tokenExpiry, expiry > Date() {
            return
        }

        let endpoint = "\(baseURL)/login"
        guard let url = URL(string: endpoint) else {
            throw TVDBError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["apiKey": apiKey]  // Must be "apiKey" not "apikey" - matches Seerr exactly
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TVDBError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw TVDBError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let authResponse = try decoder.decode(TVDBAuthResponse.self, from: data)
        authToken = authResponse.data.token

        // Token is valid for 1 month, but we'll refresh after 29 days to be safe
        tokenExpiry = Date().addingTimeInterval(29 * 24 * 60 * 60)
    }

    // MARK: - Episode Endpoints

    /// Get season details with episodes from TVDB - EXACT Seerr implementation
    /// Source: seerr/server/api/tvdb/index.ts getTvSeason() and getTvdbSeasonData()
    /// - Parameters:
    ///   - tvdbId: TVDB series ID
    ///   - seasonNumber: Season number
    ///   - language: Language code (ISO 639-1, e.g., "en", "fr", "ja"). Will be converted to TVDB format. Defaults to "en"
    /// - Returns: Array of episodes for the season
    func fetchSeasonDetails(tvdbId: Int, seasonNumber: Int, language: String = "en") async throws -> [Episode] {
        // Authenticate first
        try await authenticate()

        guard let token = authToken else {
            throw TVDBError.authenticationFailed
        }

        // Convert TMDB language code to TVDB format
        let tvdbLanguage = convertTMDBToTVDB(language)
        print("🌍 User requested language: \(language) → TVDB language: \(tvdbLanguage)")

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Step 1: Get series extended info to check translation availability
        // Source: seerr/server/api/tvdb/index.ts:322-378
        let seriesEndpoint = "\(baseURL)/series/\(tvdbId)/extended"
        var seriesComponents = URLComponents(string: seriesEndpoint)!
        seriesComponents.queryItems = [
            URLQueryItem(name: "meta", value: "episodes"),
            URLQueryItem(name: "short", value: "true")
        ]

        guard let seriesURL = seriesComponents.url else {
            throw TVDBError.invalidURL
        }

        var seriesRequest = URLRequest(url: seriesURL)
        seriesRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (seriesData, seriesResponse) = try await URLSession.shared.data(for: seriesRequest)

        guard let httpResponse = seriesResponse as? HTTPURLResponse else {
            throw TVDBError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw TVDBError.httpError(statusCode: httpResponse.statusCode)
        }

        let seriesExtended = try decoder.decode(TVDBSeriesExtendedResponse.self, from: seriesData)

        // Find the season we want
        guard let season = seriesExtended.data.seasons?.first(where: { $0.number == seasonNumber }) else {
            print("⚠️ Season \(seasonNumber) not found in TVDB data")
            return []
        }

        // Debug: Print available translations
        if let translations = season.nameTranslations {
            print("📋 Available translations for season \(seasonNumber): \(translations)")
        } else {
            print("⚠️ No nameTranslations array for season \(seasonNumber)")
        }

        // Step 2: Check if translation is available for this season
        // Source: seerr/server/api/tvdb/index.ts:348-378
        // NOTE: Due to a bug in Seerr's code (line 362), availableTranslation.filter() always returns
        // a truthy array, so Seerr ALWAYS uses getSeasonWithTranslation() regardless of availability.
        // We replicate this exact behavior for consistency.
        let availableTranslation = season.nameTranslations?.filter { translation in
            translation == tvdbLanguage || translation == "eng"
        }

        // Seerr's bug: `if (!availableTranslation)` is always false because array is truthy
        // So it ALWAYS calls getSeasonWithTranslation()
        // We replicate this by always using the translation endpoint
        print("✅ Using /episodes/default endpoint with language: \(tvdbLanguage)")
        return try await fetchEpisodesWithTranslation(
            tvdbId: tvdbId,
            seasonNumber: seasonNumber,
            language: tvdbLanguage,
            token: token,
            decoder: decoder
        )
    }

    /// Fetch episodes with translations using /series/{id}/episodes/default/{language} endpoint
    /// This endpoint returns episodes with TRANSLATED names directly in episode.name field
    /// Source: seerr/server/api/tvdb/index.ts:380-461 getSeasonWithTranslation()
    private func fetchEpisodesWithTranslation(
        tvdbId: Int,
        seasonNumber: Int,
        language: String,
        token: String,
        decoder: JSONDecoder
    ) async throws -> [Episode] {
        var allEpisodes: [TVDBEpisode] = []
        var page = 0
        let maxPages = 50  // Seerr's limit

        // Pagination loop - Seerr fetches up to 50 pages
        while page < maxPages {
            let endpoint = "\(baseURL)/series/\(tvdbId)/episodes/default/\(language)"
            var components = URLComponents(string: endpoint)!
            // NOTE: Seerr only passes "page" parameter, NOT "season"
            // Episodes are filtered by seasonNumber client-side after fetching
            components.queryItems = [
                URLQueryItem(name: "page", value: "\(page)")
            ]

            guard let url = components.url else {
                throw TVDBError.invalidURL
            }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TVDBError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw TVDBError.httpError(statusCode: httpResponse.statusCode)
            }

            let episodesResponse = try decoder.decode(TVDBEpisodesWithLinksResponse.self, from: data)

            // Add episodes from this page
            if let episodes = episodesResponse.data.episodes {
                allEpisodes.append(contentsOf: episodes)
            }

            // Check if there's a next page
            if episodesResponse.links?.next == nil {
                break
            }

            page += 1
        }

        print("📺 Fetched \(allEpisodes.count) episodes from TVDB /episodes/default endpoint")

        // Filter by season number client-side (Seerr does this at line 511)
        // The API returns episodes from ALL seasons, so we must filter
        let seasonEpisodes = allEpisodes.filter { $0.seasonNumber == seasonNumber }
        print("📺 Filtered to \(seasonEpisodes.count) episodes for season \(seasonNumber)")

        // Convert to our Episode model
        return seasonEpisodes.map { tvdbEpisode -> Episode in
            if let image = tvdbEpisode.image {
                print("📸 TVDB Episode \(tvdbEpisode.id) image: \(image)")
            }

            return Episode(
                id: tvdbEpisode.id,
                name: tvdbEpisode.name,  // Already translated from API!
                airDate: tvdbEpisode.aired,
                episodeNumber: tvdbEpisode.number,
                overview: tvdbEpisode.overview,
                productionCode: nil,
                seasonNumber: tvdbEpisode.seasonNumber,
                showId: tvdbEpisode.seriesId,
                stillPath: tvdbEpisode.image,
                voteAverage: nil,
                voteCount: nil
            )
        }
    }

    /// Fetch episodes in original language using /seasons/{id}/extended endpoint
    /// Fallback when translation is not available
    /// Source: seerr/server/api/tvdb/index.ts:463-498 getSeasonWithOriginalLanguage()
    private func fetchEpisodesOriginalLanguage(
        seasonId: Int,
        seasonNumber: Int,
        token: String,
        decoder: JSONDecoder
    ) async throws -> [Episode] {
        let endpoint = "\(baseURL)/seasons/\(seasonId)/extended"

        guard let url = URL(string: endpoint) else {
            throw TVDBError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TVDBError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw TVDBError.httpError(statusCode: httpResponse.statusCode)
        }

        let seasonExtended = try decoder.decode(TVDBSeasonExtendedResponse.self, from: data)

        print("📺 Fetched \(seasonExtended.data.episodes.count) episodes from TVDB /seasons/extended endpoint")

        // Convert to our Episode model
        return seasonExtended.data.episodes.map { tvdbEpisode -> Episode in
            if let image = tvdbEpisode.image {
                print("📸 TVDB Episode \(tvdbEpisode.id) image: \(image)")
            }

            return Episode(
                id: tvdbEpisode.id,
                name: tvdbEpisode.name,
                airDate: tvdbEpisode.aired,
                episodeNumber: tvdbEpisode.number,
                overview: tvdbEpisode.overview,
                productionCode: nil,
                seasonNumber: tvdbEpisode.seasonNumber,
                showId: tvdbEpisode.seriesId,
                stillPath: tvdbEpisode.image,
                voteAverage: nil,
                voteCount: nil
            )
        }
    }
}

// MARK: - TVDB Models

/// TVDB Authentication Response
private struct TVDBAuthResponse: Codable {
    let data: TVDBAuthData
}

private struct TVDBAuthData: Codable {
    let token: String
}

/// TVDB Series Extended Response
private struct TVDBSeriesExtendedResponse: Codable {
    let data: TVDBSeriesExtended
}

private struct TVDBSeriesExtended: Codable {
    let seasons: [TVDBSeasonInfo]?
}

private struct TVDBSeasonInfo: Codable {
    let id: Int
    let number: Int
    let nameTranslations: [String]?
}

/// TVDB Season Extended Response
private struct TVDBSeasonExtendedResponse: Codable {
    let data: TVDBSeasonExtended
}

private struct TVDBSeasonExtended: Codable {
    let episodes: [TVDBEpisode]
}

/// TVDB Episodes Response with pagination links
/// Used by /series/{id}/episodes/default/{language} endpoint
private struct TVDBEpisodesWithLinksResponse: Codable {
    let data: TVDBEpisodesData
    let links: TVDBLinks?
}

private struct TVDBEpisodesData: Codable {
    let episodes: [TVDBEpisode]?
}

private struct TVDBLinks: Codable {
    let next: String?
}

/// TVDB Episode model
private struct TVDBEpisode: Codable {
    let id: Int
    let seriesId: Int?
    let name: String?
    let aired: String?
    let overview: String?
    let image: String?
    let number: Int?
    let seasonNumber: Int?
    // Note: nameTranslations is just an array of available language codes, not the actual translations
    // The translations would need to be fetched separately, but for now we use the default name
    let nameTranslations: [String]?
    let overviewTranslations: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case seriesId
        case name
        case aired
        case overview
        case image
        case number
        case seasonNumber
        case nameTranslations
        case overviewTranslations
    }
}

// MARK: - Errors

enum TVDBError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case authenticationFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid TVDB URL"
        case .invalidResponse:
            return "Invalid response from TVDB"
        case .httpError(let code):
            return "TVDB HTTP error: \(code)"
        case .authenticationFailed:
            return "Failed to authenticate with TVDB"
        }
    }
}
