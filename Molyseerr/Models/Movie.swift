//
//  Movie.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import Foundation

/// Genre model
struct Genre: Codable, Identifiable {
    let id: Int
    let name: String
}

/// Production company model
struct ProductionCompany: Codable, Identifiable {
    let id: Int
    let name: String
    let logoPath: String?
    let originCountry: String?
}

/// Cast member model
struct Cast: Codable, Identifiable {
    let id: Int
    let castId: Int?
    let character: String?
    let creditId: String?
    let gender: Int?
    let name: String
    let order: Int?
    let profilePath: String?
}

/// Movie search result (from Discover/Trending)
/// Source: seerr-api.yml MovieResult schema
struct MovieResult: Codable, Identifiable {
    let id: Int  // TMDB ID
    let adult: Bool?
    let backdropPath: String?
    let posterPath: String?
    let genreIds: [Int]?
    let originalLanguage: String?
    let originalTitle: String?
    let overview: String?
    let popularity: Double?
    let releaseDate: String?
    let title: String
    let video: Bool?
    let voteAverage: Double?
    let voteCount: Int?
    let mediaType: String?

    /// CRITICAL: MediaInfo contains status for button logic (TVOS_ARCH_SPEC.md Section 2.1)
    let mediaInfo: MediaInfo?
}

/// Full movie details
/// Source: seerr-api.yml MovieDetails schema
struct MovieDetails: Codable, Identifiable {
    let id: Int
    let imdbId: String?
    let adult: Bool?
    let backdropPath: String?
    let posterPath: String?
    let budget: Int?
    let genres: [Genre]?
    let homepage: String?
    let originalLanguage: String?
    let originalTitle: String?
    let overview: String?
    let popularity: Double?
    let productionCompanies: [ProductionCompany]?
    let releaseDate: String?
    let revenue: Int?
    let runtime: Int?
    let status: String?
    let tagline: String?
    let title: String
    let video: Bool?
    let voteAverage: Double?
    let voteCount: Int?

    /// Credits (cast and crew)
    let credits: Credits?

    /// CRITICAL: Contains status, requests, permissions (TVOS_ARCH_SPEC.md Section 2.2)
    let mediaInfo: MediaInfo?
}

/// Credits (cast and crew)
struct Credits: Codable {
    let cast: [Cast]?
    let crew: [Cast]?
}
