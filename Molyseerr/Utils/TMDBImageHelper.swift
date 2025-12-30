//
//  TMDBImageHelper.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import Foundation

/// Helper for building TMDB image URLs
/// Reference: https://developers.themoviedb.org/3/getting-started/images
enum TMDBImageHelper {

    /// TMDB image base URL
    private static let baseURL = "https://image.tmdb.org/t/p/"

    /// Image size options for different use cases
    enum ImageSize: String {
        // Poster sizes (2:3 ratio)
        case posterSmall = "w185"
        case posterMedium = "w342"
        case posterLarge = "w500"     // Recommended for grids (TECH_RULES.md)

        // Backdrop sizes (16:9 ratio)
        case backdropSmall = "w300"
        case backdropMedium = "w780"
        case backdropLarge = "w1280"

        // Original size (for both poster and backdrop)
        case original = "original"  // For hero banner (TECH_RULES.md)
    }

    /// Build full TMDB image URL
    /// - Parameters:
    ///   - path: Image path from API (e.g., "/abc123.jpg")
    ///   - size: Desired image size
    /// - Returns: Full URL or nil if path is invalid
    static func imageURL(path: String?, size: ImageSize) -> URL? {
        guard let path = path, !path.isEmpty else {
            return nil
        }

        // Remove leading slash if present
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path

        let urlString = "\(baseURL)\(size.rawValue)/\(cleanPath)"
        return URL(string: urlString)
    }

    /// Get poster URL for media cards (w500 size as per TECH_RULES.md)
    static func posterURL(path: String?) -> URL? {
        return imageURL(path: path, size: .posterLarge)
    }

    /// Get poster URL with custom size
    static func posterURL(path: String?, size: ImageSize) -> URL? {
        return imageURL(path: path, size: size)
    }

    /// Get backdrop URL for hero banner (original size as per TECH_RULES.md)
    static func backdropURL(path: String?) -> URL? {
        return imageURL(path: path, size: .original)
    }

    /// Get backdrop URL with custom size
    static func backdropURL(path: String?, size: ImageSize) -> URL? {
        return imageURL(path: path, size: size)
    }

    /// Get logo URL (for production companies, networks)
    static func logoURL(path: String?) -> URL? {
        return imageURL(path: path, size: .posterMedium)
    }

    /// Get still/thumbnail URL for episodes (16:9 landscape images)
    static func stillURL(path: String?) -> URL? {
        return imageURL(path: path, size: .backdropMedium)
    }
}
