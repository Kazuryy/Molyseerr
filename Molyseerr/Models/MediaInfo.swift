//
//  MediaInfo.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import Foundation

/// Media entity from Seerr database
/// Source: seerr-api.yml MediaInfo schema & TVOS_ARCH_SPEC.md Section 3.6
/// CRITICAL: Contains status, requests, and metadata needed for button logic
struct MediaInfo: Codable, Identifiable {
    let id: Int
    let tmdbId: Int
    let tvdbId: Int?
    let status: MediaStatus
    let status4k: MediaStatus?
    let requests: [MediaRequest]?
    let createdAt: String
    let updatedAt: String
    let plexUrl: String?
    let jellyfinMediaId: String?
    let mediaAddedAt: String?

    // TMDB metadata fields
    let mediaType: MediaType
    let title: String?
    let originalTitle: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let voteCount: Int?
    let popularity: Double?
    let genres: [Genre]?
    let originalLanguage: String?
    let originCountry: [String]?

    enum CodingKeys: String, CodingKey {
        case id, tmdbId, tvdbId, status, status4k, requests
        case createdAt, updatedAt, plexUrl, jellyfinMediaId, mediaAddedAt
        case mediaType, title, originalTitle, overview, genres
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case popularity
        case originalLanguage = "original_language"
        case originCountry = "origin_country"
    }
}
