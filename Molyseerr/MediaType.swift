//
//  MediaType.swift
//  Molyseerr
//
//  Created by Assistant on 27/12/2025.
//

import Foundation

/// Media type enum for movies and TV shows
enum MediaType: String, Codable {
    case movie = "movie"
    case tv = "tv"
}

/// Media status enum
enum MediaStatus: String, Codable {
    case unknown
    case pending
    case processing
    case available
    case partiallyAvailable = "PARTIALLY_AVAILABLE"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        
        switch rawValue {
        case 1:
            self = .unknown
        case 2:
            self = .pending
        case 3:
            self = .processing
        case 4:
            self = .available
        case 5:
            self = .partiallyAvailable
        default:
            self = .unknown
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let value: Int
        switch self {
        case .unknown:
            value = 1
        case .pending:
            value = 2
        case .processing:
            value = 3
        case .available:
            value = 4
        case .partiallyAvailable:
            value = 5
        }
        try container.encode(value)
    }
}
