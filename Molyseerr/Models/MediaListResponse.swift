//
//  MediaListResponse.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import Foundation

/// Response for /api/v1/media endpoint
/// Source: seerr-api.yml MediaResultsResponse
struct MediaListResponse: Codable {
    let pageInfo: MediaPageInfo
    let results: [MediaInfo]
}

/// Page info for media lists
struct MediaPageInfo: Codable {
    let pages: Int
    let pageSize: Int
    let results: Int
    let page: Int
}

/// Calendar item for Today's Releases (full version)
/// Source: seerr/server/routes/calendar.ts CalendarItem interface
struct CalendarItem: Codable, Identifiable {
    let type: String  // "movie" or "tv"
    let tmdbId: Int
    let tvdbId: Int?
    let title: String
    let seasonNumber: Int?      // TV only
    let episodeNumber: Int?     // TV only
    let episodeTitle: String?   // TV only
    let releaseDate: String     // ISO format
    let overview: String?
    let status: String          // "released", "announced", "inCinemas", "available"
    let hasFile: Bool
    let inWatchlist: Bool
    let countdown: Int          // Seconds until release
    let posterPath: String?
    let backdropPath: String?

    // Computed ID for Identifiable conformance
    var id: String {
        // Generate unique ID from tmdbId + seasonNumber + episodeNumber
        if let season = seasonNumber, let episode = episodeNumber {
            return "\(tmdbId)-s\(season)e\(episode)"
        }
        return "\(tmdbId)"
    }

    /// Computed property for episode display (e.g., "1x09")
    var episodeLabel: String? {
        guard type == "tv",
              let season = seasonNumber,
              let episode = episodeNumber else {
            return nil
        }
        return "\(season)x\(String(format: "%02d", episode))"
    }

    /// Status color based on status and hasFile
    enum StatusColor {
        case watchlist  // Gold/Yellow - In watchlist
        case available  // Green - Downloaded/Available
        case released   // Orange - Released but not downloaded
        case announced  // Blue - Announced/Coming soon
        case inCinemas  // Purple - In theaters
        case unknown    // Gray - Unknown status
    }

    var statusColor: StatusColor {
        if inWatchlist {
            return .watchlist
        } else if hasFile {
            return .available
        } else if status == "released" || status == "available" {
            return .released
        } else if status == "announced" {
            return .announced
        } else if status == "inCinemas" {
            return .inCinemas
        } else {
            return .unknown
        }
    }

    /// Release time display (start time + estimated end time)
    /// Movies: +120 minutes, TV: +50 minutes
    func timeRange() -> String? {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: releaseDate) else {
            return nil
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let startTime = timeFormatter.string(from: date)

        // Calculate end time based on type
        let duration: TimeInterval = type == "movie" ? 120 * 60 : 50 * 60  // seconds
        let endDate = date.addingTimeInterval(duration)
        let endTime = timeFormatter.string(from: endDate)

        return "\(startTime) - \(endTime)"
    }

    /// Full poster URL
    var posterURL: String? {
        guard let posterPath = posterPath else { return nil }
        return TMDBImageHelper.posterURL(path: posterPath)?.absoluteString
    }

    /// Full backdrop URL
    var backdropURL: String? {
        guard let backdropPath = backdropPath else { return nil }
        return TMDBImageHelper.backdropURL(path: backdropPath)?.absoluteString
    }

    /// Formatted release date
    var releaseDateFormatted: String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: releaseDate) else { return nil }

        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

/// Calendar day grouping
/// Source: seerr/server/routes/calendar.ts CalendarDay interface
struct CalendarDay: Codable {
    let date: String  // YYYY-MM-DD format
    let items: [CalendarItem]
}

/// Calendar API response
/// Source: seerr/server/routes/calendar.ts CalendarResponse interface
struct CalendarResponse: Codable {
    let results: [CalendarDay]
}

// MARK: - CalendarItem Extension

extension CalendarItem {
    /// Convert CalendarItem to MediaResult for navigation
    func toMediaResult() -> MediaResult {
        if type == "movie" {
            let movie = MovieResult(
                id: tmdbId,
                adult: false,
                backdropPath: backdropPath,
                posterPath: posterPath,
                genreIds: nil,
                originalLanguage: "en",
                originalTitle: title,
                overview: overview,
                popularity: nil,
                releaseDate: releaseDate,
                firstAirDate: nil,
                title: title,
                name: nil,
                originCountry: nil,
                originalName: nil,
                video: nil,
                voteAverage: nil,
                voteCount: nil,
                mediaType: "movie",
                mediaInfo: nil
            )
            return .movie(movie)
        } else {
            let tv = TVResult(
                id: tmdbId,
                backdropPath: backdropPath,
                posterPath: posterPath,
                genreIds: nil,
                originalLanguage: "en",
                originalName: title,
                overview: overview,
                popularity: nil,
                firstAirDate: releaseDate,
                name: title,
                voteAverage: nil,
                voteCount: nil,
                originCountry: nil,
                mediaType: "tv",
                mediaInfo: nil
            )
            return .tv(tv)
        }
    }
}

/// Studio/Network information
struct Studio: Codable, Identifiable {
    let id: Int
    let name: String
    let logoPath: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case logoPath = "logo_path"
    }
}

/// Keyword information
struct Keyword: Codable, Identifiable {
    let id: Int
    let name: String
}

/// Watchlist item
struct WatchlistItem: Codable, Identifiable {
    let id: Int?
    let ratingKey: String?
    let title: String
    let mediaType: String
    let tmdbId: Int?

    var displayId: Int {
        id ?? tmdbId ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case id, ratingKey, title, mediaType, tmdbId
    }
}
