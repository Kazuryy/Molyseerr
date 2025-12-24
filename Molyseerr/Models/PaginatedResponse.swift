//
//  PaginatedResponse.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import Foundation

/// Paginated response wrapper
/// Source: seerr-api.yml PageInfo schema & TVOS_ARCH_SPEC.md Section 3.6
struct PaginatedResponse<T: Codable>: Codable {
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let results: [T]
}

/// Media search result (union type for movies and TV)
enum MediaResult: Codable, Identifiable {
    case movie(MovieResult)
    case tv(TVResult)

    var id: Int {
        switch self {
        case .movie(let movie):
            return movie.id
        case .tv(let tv):
            return tv.id
        }
    }

    var mediaType: MediaType {
        switch self {
        case .movie:
            return .movie
        case .tv:
            return .tv
        }
    }

    var title: String {
        switch self {
        case .movie(let movie):
            return movie.title
        case .tv(let tv):
            return tv.name
        }
    }

    var posterPath: String? {
        switch self {
        case .movie(let movie):
            return movie.posterPath
        case .tv(let tv):
            return tv.posterPath
        }
    }

    var backdropPath: String? {
        switch self {
        case .movie(let movie):
            return movie.backdropPath
        case .tv(let tv):
            return tv.backdropPath
        }
    }

    var mediaInfo: MediaInfo? {
        switch self {
        case .movie(let movie):
            return movie.mediaInfo
        case .tv(let tv):
            return tv.mediaInfo
        }
    }

    // Custom Codable implementation to handle dynamic decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try to decode as MovieResult first
        if let movie = try? container.decode(MovieResult.self) {
            // Check mediaType field if present
            if let mediaType = movie.mediaType, mediaType == "tv" {
                // This is actually a TV show, try decoding as TVResult
                let tv = try container.decode(TVResult.self)
                self = .tv(tv)
            } else {
                self = .movie(movie)
            }
        } else if let tv = try? container.decode(TVResult.self) {
            self = .tv(tv)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode MediaResult"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .movie(let movie):
            try container.encode(movie)
        case .tv(let tv):
            try container.encode(tv)
        }
    }
}
