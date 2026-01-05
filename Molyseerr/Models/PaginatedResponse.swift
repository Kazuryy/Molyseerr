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
enum MediaResult: Codable, Identifiable, Hashable {
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
            return movie.displayTitle
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

    var overview: String? {
        switch self {
        case .movie(let movie):
            return movie.overview
        case .tv(let tv):
            return tv.overview
        }
    }

    // Custom Codable implementation to handle dynamic decoding
    init(from decoder: Decoder) throws {
        // Peek at the media_type field to determine which type to decode
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let mediaTypeString = try? container.decode(String.self, forKey: .mediaType) {
            // Now decode the full object based on media_type
            let singleValueContainer = try decoder.singleValueContainer()

            if mediaTypeString == "tv" {
                let tv = try singleValueContainer.decode(TVResult.self)
                self = .tv(tv)
            } else if mediaTypeString == "movie" {
                let movie = try singleValueContainer.decode(MovieResult.self)
                self = .movie(movie)
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: .mediaType,
                    in: container,
                    debugDescription: "Unknown media_type: \(mediaTypeString)"
                )
            }
        } else {
            // Fallback: No media_type field, try to decode as MovieResult then TVResult
            let singleValueContainer = try decoder.singleValueContainer()

            if let movie = try? singleValueContainer.decode(MovieResult.self) {
                self = .movie(movie)
            } else if let tv = try? singleValueContainer.decode(TVResult.self) {
                self = .tv(tv)
            } else {
                throw DecodingError.dataCorruptedError(
                    in: singleValueContainer,
                    debugDescription: "Cannot decode MediaResult - neither MovieResult nor TVResult"
                )
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case mediaType  // No need for = "media_type" since JSONDecoder already converted it
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
