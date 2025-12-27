//
//  TMDBImageHelper.swift
//  Molyseerr
//
//  Created by Assistant on 27/12/2025.
//

import Foundation

/// Helper for constructing TMDB image URLs
/// TMDB images are served via Seerr proxy or directly from TMDB
struct TMDBImageHelper {
    
    /// Image size options
    enum ImageSize: String {
        case posterSmall = "w92"
        case posterMedium = "w154"
        case posterLarge = "w185"
        case posterXLarge = "w342"
        case posterOriginal = "original"
        
        case backdropSmall = "w300"
        case backdropMedium = "w780"
        case backdropLarge = "w1280"
        case backdropOriginal = "original"
        
        case profileSmall = "w45"
        case profileMedium = "w185"
        case profileLarge = "h632"
        case profileOriginal = "original"
    }
    
    // TMDB image base URL (can be proxied through Seerr)
    private static let baseURL = "https://image.tmdb.org/t/p"
    
    /// Build poster URL
    static func posterURL(path: String?, size: ImageSize = .posterXLarge) -> URL? {
        guard let path = path, !path.isEmpty else { return nil }
        let urlString = "\(baseURL)/\(size.rawValue)\(path)"
        return URL(string: urlString)
    }
    
    /// Build backdrop URL
    static func backdropURL(path: String?, size: ImageSize = .backdropLarge) -> URL? {
        guard let path = path, !path.isEmpty else { return nil }
        let urlString = "\(baseURL)/\(size.rawValue)\(path)"
        return URL(string: urlString)
    }
    
    /// Build profile image URL
    static func profileURL(path: String?, size: ImageSize = .profileMedium) -> URL? {
        guard let path = path, !path.isEmpty else { return nil }
        let urlString = "\(baseURL)/\(size.rawValue)\(path)"
        return URL(string: urlString)
    }
    
    /// Generic image URL builder
    static func imageURL(path: String?, size: ImageSize = .posterXLarge) -> URL? {
        guard let path = path, !path.isEmpty else { return nil }
        let urlString = "\(baseURL)/\(size.rawValue)\(path)"
        return URL(string: urlString)
    }
}
