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
}

/// TV show search result (from Discover/Trending)
/// Source: seerr-api.yml TvResult schema
struct TVResult: Codable, Identifiable {
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
}

/// Creator model (for TV shows)
struct Creator: Codable, Identifiable {
    let id: Int
    let name: String
    let gender: Int?
    let profilePath: String?
}
