//
//  TVShow.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import Foundation

/// Episode model
struct Episode: Codable, Identifiable {
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

/// Season model
struct Season: Codable, Identifiable {
    let id: Int
    let airDate: String?
    let episodeCount: Int?
    let name: String?
    let overview: String?
    let posterPath: String?
    let seasonNumber: Int

    /// Display title for the season (handles specials, unnamed seasons, etc.)
    var displayTitle: String {
        // If we have a name from TMDB, use it
        if let name = name, !name.isEmpty {
            return name
        }

        // Otherwise, generate a name based on season number
        if seasonNumber == 0 {
            return "Specials"
        } else {
            return "Season \(seasonNumber)"
        }
    }
}

/// TV show search result (from Discover/Trending)
/// Source: seerr-api.yml TvResult schema
struct TVResult: Codable, Identifiable, Hashable {
    let id: Int  // TMDB ID
    let backdropPath: String?
    let posterPath: String?
    let genreIds: [Int]?
    let originalLanguage: String?
    let originalName: String?
    let overview: String?
    let popularity: Double?
    let firstAirDate: String?
    let name: String
    let voteAverage: Double?
    let voteCount: Int?
    let originCountry: [String]?
    let mediaType: String?

    /// CRITICAL: MediaInfo contains status for button logic (TVOS_ARCH_SPEC.md Section 2.1)
    let mediaInfo: MediaInfo?
}

/// Full TV show details
/// Source: seerr-api.yml TvDetails schema
struct TVDetails: Codable, Identifiable {
    let id: Int
    let backdropPath: String?
    let posterPath: String?
    let createdBy: [Creator]?
    let episodeRunTime: [Int]?
    let firstAirDate: String?
    let genres: [Genre]?
    let homepage: String?
    let inProduction: Bool?
    let languages: [String]?
    let lastAirDate: String?
    let lastEpisodeToAir: Episode?
    let name: String
    let nextEpisodeToAir: Episode?
    let networks: [ProductionCompany]?
    let numberOfEpisodes: Int?
    let numberOfSeasons: Int?
    let originCountry: [String]?
    let originalLanguage: String?
    let originalName: String?
    let overview: String?
    let popularity: Double?
    let productionCompanies: [ProductionCompany]?
    let seasons: [Season]?
    let status: String?
    let tagline: String?
    let type: String?
    let voteAverage: Double?
    let voteCount: Int?

    /// Credits (cast and crew)
    let credits: Credits?

    /// CRITICAL: Contains status, requests, permissions (TVOS_ARCH_SPEC.md Section 2.2)
    let mediaInfo: MediaInfo?

    enum CodingKeys: String, CodingKey {
        case id, createdBy, episodeRunTime, genres, homepage, inProduction
        case languages, name, networks, popularity, productionCompanies
        case seasons, status, tagline, type, credits, mediaInfo
        case backdropPath = "backdrop_path"
        case posterPath = "poster_path"
        case firstAirDate = "first_air_date"
        case lastAirDate = "last_air_date"
        case lastEpisodeToAir = "last_episode_to_air"
        case nextEpisodeToAir = "next_episode_to_air"
        case numberOfEpisodes = "number_of_episodes"
        case numberOfSeasons = "number_of_seasons"
        case originCountry = "origin_country"
        case originalLanguage = "original_language"
        case originalName = "original_name"
        case overview
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }

    /// Display name (fallback to original if needed)
    var displayName: String {
        name.isEmpty ? (originalName ?? "Unknown") : name
    }

    /// Formatted runtime (e.g., "45m")
    var formattedRuntime: String? {
        guard let episodeRunTime = episodeRunTime, let runtime = episodeRunTime.first, runtime > 0 else { return nil }
        return "\(runtime)m"
    }

    /// First air year (e.g., "2020")
    var firstAirYear: String? {
        guard let firstAirDate = firstAirDate, !firstAirDate.isEmpty else { return nil }
        let components = firstAirDate.split(separator: "-")
        return components.first.map(String.init)
    }

    /// Metadata provider to use (TMDB or TVDB)
    /// Returns TVDB if tvdbId is present, otherwise defaults to TMDB
    var metadataProvider: MetadataProvider {
        if let tvdbId = mediaInfo?.tvdbId, tvdbId > 0 {
            return .tvdb(id: tvdbId)
        } else {
            return .tmdb(id: id)
        }
    }
}

/// Metadata provider enum
enum MetadataProvider {
    case tmdb(id: Int)
    case tvdb(id: Int)

    var isTVDB: Bool {
        if case .tvdb = self {
            return true
        }
        return false
    }

    var id: Int {
        switch self {
        case .tmdb(let id), .tvdb(let id):
            return id
        }
    }
}

/// Creator model (for TV shows)
struct Creator: Codable, Identifiable {
    let id: Int
    let name: String
    let gender: Int?
    let profilePath: String?
}
