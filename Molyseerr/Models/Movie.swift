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

/// Crew member model
struct Crew: Codable, Identifiable {
    let id: Int
    let creditId: String?
    let department: String
    let gender: Int?
    let job: String
    let name: String
    let profilePath: String?
}

/// Related video (trailer, etc.)
struct RelatedVideo: Codable, Identifiable {
    let url: String?
    let key: String
    let name: String
    let size: Int?
    let type: String
    let site: String

    var id: String { key }
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
    let firstAirDate: String?  // For TV shows in mixed results
    let title: String?  // Optional because TV shows use "name" instead
    let name: String?   // For TV shows in mixed results
    let originCountry: [String]?  // For TV shows
    let originalName: String?  // For TV shows
    let video: Bool?
    let voteAverage: Double?
    let voteCount: Int?
    let mediaType: String?

    /// CRITICAL: MediaInfo contains status for button logic (TVOS_ARCH_SPEC.md Section 2.1)
    let mediaInfo: MediaInfo?

    /// Computed property to get the display title (works for both movies and TV)
    var displayTitle: String {
        return title ?? name ?? "Unknown"
    }
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
    let relatedVideos: [RelatedVideo]?
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

    enum CodingKeys: String, CodingKey {
        case id, adult, budget, genres, homepage, relatedVideos, popularity
        case productionCompanies, revenue, runtime, status, tagline, title
        case video, credits, mediaInfo
        case imdbId = "imdb_id"
        case backdropPath = "backdrop_path"
        case posterPath = "poster_path"
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case overview
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }

    /// Display title (fallback to original if needed)
    var displayTitle: String {
        title.isEmpty ? (originalTitle ?? "Unknown") : title
    }

    /// Formatted runtime (e.g., "2h 30m")
    var formattedRuntime: String? {
        guard let runtime = runtime, runtime > 0 else { return nil }
        let hours = runtime / 60
        let minutes = runtime % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Release year (e.g., "2023")
    var releaseYear: String? {
        guard let releaseDate = releaseDate, !releaseDate.isEmpty else { return nil }
        let components = releaseDate.split(separator: "-")
        return components.first.map(String.init)
    }
}

/// Credits (cast and crew)
struct Credits: Codable {
    let cast: [Cast]?
    let crew: [Crew]?
}
