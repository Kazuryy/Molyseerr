//
//  TVShow.swift
//  Molyseerr
//
//  Created by Assistant on 27/12/2025.
//

import Foundation

/// TV show search result (from Discover/Trending)
/// Source: seerr-api.yml TVResult schema
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
    
    /// CRITICAL: MediaInfo contains status for button logic
    let mediaInfo: MediaInfo?
}

/// Full TV show details
/// Source: seerr-api.yml TVDetails schema
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
    let name: String
    let networks: [Network]?
    let numberOfEpisodes: Int?
    let numberOfSeasons: Int?
    let originCountry: [String]?
    let originalLanguage: String?
    let originalName: String?
    let overview: String?
    let popularity: Double?
    let productionCompanies: [ProductionCompany]?
    let status: String?
    let tagline: String?
    let type: String?
    let voteAverage: Double?
    let voteCount: Int?
    let relatedVideos: [RelatedVideo]?
    
    /// Credits (cast and crew)
    let credits: Credits?
    
    /// CRITICAL: Contains status, requests, permissions
    let mediaInfo: MediaInfo?
    
    /// Display name (fallback to original if needed)
    var displayName: String {
        name.isEmpty ? (originalName ?? "Unknown") : name
    }
    
    /// Formatted runtime (e.g., "45m")
    var formattedRuntime: String? {
        guard let runtime = episodeRunTime?.first, runtime > 0 else { return nil }
        return "\(runtime)m"
    }
    
    /// First air year (e.g., "2023")
    var firstAirYear: String? {
        guard let firstAirDate = firstAirDate, !firstAirDate.isEmpty else { return nil }
        let components = firstAirDate.split(separator: "-")
        return components.first.map(String.init)
    }
}

/// Creator model
struct Creator: Codable, Identifiable {
    let id: Int
    let creditId: String?
    let name: String
    let gender: Int?
    let profilePath: String?
}

/// Network model
struct Network: Codable, Identifiable {
    let id: Int
    let name: String
    let logoPath: String?
    let originCountry: String?
}
