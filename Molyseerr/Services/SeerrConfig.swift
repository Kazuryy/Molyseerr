//
//  SeerrConfig.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import Foundation

/// Configuration for Seerr API
/// Centralized configuration as per TECH_RULES.md Section 3
struct SeerrConfig {
    /// API Base URL (default from seerr-api.yml)
    static let defaultBaseURL = "http://localhost:5055"

    /// TMDB Image CDN base URLs
    /// Source: TVOS_ARCH_SPEC.md Section 5.3
    static let tmdbImageBaseURL = "https://image.tmdb.org/t/p"

    /// Image sizes for tvOS (TECH_RULES.md Section 4)
    enum ImageSize: String {
        /// For poster grids (500px width)
        case poster = "w500"

        /// For backdrop/background images (original quality for 4K displays)
        case backdrop = "original"

        /// For profile images
        case profile = "w185"
    }

    /// Build TMDB image URL
    /// - Parameters:
    ///   - path: Image path from API (e.g., "/abc123.jpg")
    ///   - size: Desired image size
    /// - Returns: Full image URL
    static func imageURL(path: String?, size: ImageSize = .poster) -> URL? {
        guard let path = path else { return nil }
        let urlString = "\(tmdbImageBaseURL)/\(size.rawValue)\(path)"
        return URL(string: urlString)
    }
}
