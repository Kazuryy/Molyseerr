//
//  DiscoverSlider.swift
//  Molyseerr
//
//  Created by Assistant on 27/12/2025.
//

import Foundation

/// Discover slider configuration from server
/// Source: seerr-api.yml DiscoverSlider schema
struct DiscoverSlider: Codable, Identifiable {
    let id: Int
    let type: SliderType
    let title: String?
    let enabled: Bool
    let order: Int
    
    /// Display title (uses custom title or default)
    var displayTitle: String {
        title ?? type.defaultTitle
    }
}

/// Slider type enum - maps to Seerr's slider types
enum SliderType: String, Codable {
    case trending = "trending"
    case popularMovies = "popular-movies"
    case popularTV = "popular-tv"
    case upcomingMovies = "upcoming-movies"
    case upcomingTV = "upcoming-tv"
    case nowPlayingMovies = "now-playing-movies"
    case topRatedMovies = "top-rated-movies"
    case topRatedTV = "top-rated-tv"
    case airingThisWeek = "airing-this-week"
    case netflixOriginals = "netflix-originals"
    case disneyPlus = "disney-plus"
    case appleTV = "apple-tv"
    case hboMax = "hbo-max"
    case amazonPrime = "amazon-prime"
    
    /// Default title for each slider type
    var defaultTitle: String {
        switch self {
        case .trending:
            return "Trending"
        case .popularMovies:
            return "Popular Movies"
        case .popularTV:
            return "Popular TV Shows"
        case .upcomingMovies:
            return "Upcoming Movies"
        case .upcomingTV:
            return "Upcoming TV Shows"
        case .nowPlayingMovies:
            return "Now Playing in Theaters"
        case .topRatedMovies:
            return "Top Rated Movies"
        case .topRatedTV:
            return "Top Rated TV Shows"
        case .airingThisWeek:
            return "Airing This Week"
        case .netflixOriginals:
            return "Netflix Originals"
        case .disneyPlus:
            return "Disney+"
        case .appleTV:
            return "Apple TV+"
        case .hboMax:
            return "HBO Max"
        case .amazonPrime:
            return "Amazon Prime Video"
        }
    }
}
