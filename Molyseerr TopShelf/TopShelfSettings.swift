//
//  TopShelfSettings.swift
//  Molyseerr
//
//  Created by Claude on 02/01/2026.
//

import Foundation
import TVServices

/// TopShelf display mode
enum TopShelfDisplayMode: String, Codable, CaseIterable {
    case hero = "hero"
    case sectioned = "sectioned"

    var displayName: String {
        switch self {
        case .hero:
            return "Hero (Apple TV+ Style)"
        case .sectioned:
            return "Sectioned (Netflix Style)"
        }
    }
}

/// Legacy TopShelf content source (deprecated - kept for migration)
enum TopShelfContentSource: String, Codable, CaseIterable {
    case trending = "trending"
    case popularMovies = "popular_movies"
    case popularTV = "popular_tv"
    case watchlist = "watchlist"

    var displayName: String {
        switch self {
        case .trending:
            return "Trending"
        case .popularMovies:
            return "Popular Movies"
        case .popularTV:
            return "Popular TV Shows"
        case .watchlist:
            return "My Watchlist"
        }
    }
}

/// Slider configuration for TopShelf
struct TopShelfSliderConfig: Codable, Equatable {
    let id: Int
    let title: String
    let type: Int  // SliderType rawValue

    init(id: Int, title: String, type: Int) {
        self.id = id
        self.title = title
        self.type = type
    }
}

/// Shared settings for TopShelf extension
/// Uses UserDefaults with App Group to share data between app and extension
class TopShelfSettings {

    // MARK: - Singleton

    static let shared = TopShelfSettings()

    // MARK: - App Group

    private let appGroupID = "group.com.molycorp.Molyseerr.shared"
    private let userDefaults: UserDefaults?

    // MARK: - Keys

    private let displayModeKey = "topshelf_display_mode"
    private let contentSourceKey = "topshelf_content_source" // Legacy - kept for migration
    private let selectedSlidersKey = "topshelf_selected_sliders"
    private let seerrURLKey = "topshelf_seerr_url"
    private let seerrAPIKeyKey = "topshelf_seerr_api_key"
    private let sliderContentCacheKey = "topshelf_slider_content_cache" // Cache des IDs TMDB
    private let cacheTimestampKey = "topshelf_cache_timestamp" // Timestamp du dernier refresh

    // MARK: - Properties

    var displayMode: TopShelfDisplayMode {
        get {
            guard let userDefaults = userDefaults,
                  let rawValue = userDefaults.string(forKey: displayModeKey),
                  let mode = TopShelfDisplayMode(rawValue: rawValue) else {
                return .hero // Default
            }
            return mode
        }
        set {
            userDefaults?.set(newValue.rawValue, forKey: displayModeKey)
            userDefaults?.synchronize()
            notifyExtension()
        }
    }

    /// Legacy content source (deprecated)
    var contentSource: TopShelfContentSource {
        get {
            guard let userDefaults = userDefaults,
                  let rawValue = userDefaults.string(forKey: contentSourceKey),
                  let source = TopShelfContentSource(rawValue: rawValue) else {
                return .trending // Default
            }
            return source
        }
        set {
            userDefaults?.set(newValue.rawValue, forKey: contentSourceKey)
            userDefaults?.synchronize()
            notifyExtension()
        }
    }

    /// Selected sliders for TopShelf (new dynamic system)
    var selectedSliders: [TopShelfSliderConfig] {
        get {
            guard let userDefaults = userDefaults,
                  let data = userDefaults.data(forKey: selectedSlidersKey),
                  let sliders = try? JSONDecoder().decode([TopShelfSliderConfig].self, from: data) else {
                return [] // Empty by default - will fall back to legacy
            }
            return sliders
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                userDefaults?.set(encoded, forKey: selectedSlidersKey)
                userDefaults?.synchronize()
                notifyExtension()
            }
        }
    }

    /// Seerr server URL (needed for TopShelf extension)
    var seerrURL: String? {
        get {
            userDefaults?.string(forKey: seerrURLKey)
        }
        set {
            userDefaults?.set(newValue, forKey: seerrURLKey)
            userDefaults?.synchronize()
        }
    }

    /// Seerr API key (needed for TopShelf extension)
    var seerrAPIKey: String? {
        get {
            userDefaults?.string(forKey: seerrAPIKeyKey)
        }
        set {
            userDefaults?.set(newValue, forKey: seerrAPIKeyKey)
            userDefaults?.synchronize()
        }
    }

    /// Cached slider content (TMDB IDs + metadata)
    /// Format: [sliderID: [TMDBMediaID: (type, title, poster, backdrop)]]
    var sliderContentCache: [String: [[String: String]]] {
        get {
            guard let userDefaults = userDefaults,
                  let data = userDefaults.data(forKey: sliderContentCacheKey),
                  let cache = try? JSONDecoder().decode([String: [[String: String]]].self, from: data) else {
                return [:]
            }
            return cache
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                userDefaults?.set(encoded, forKey: sliderContentCacheKey)
                userDefaults?.synchronize()
            }
        }
    }

    /// Timestamp of last cache update
    var cacheTimestamp: Date? {
        get {
            userDefaults?.object(forKey: cacheTimestampKey) as? Date
        }
        set {
            userDefaults?.set(newValue, forKey: cacheTimestampKey)
            userDefaults?.synchronize()
        }
    }

    /// Check if cache is stale (older than 15 minutes)
    var isCacheStale: Bool {
        guard let timestamp = cacheTimestamp else { return true }
        let fifteenMinutes: TimeInterval = 15 * 60
        return Date().timeIntervalSince(timestamp) > fifteenMinutes
    }

    /// Update content cache for a specific slider
    func updateSliderContent(sliderID: Int, items: [[String: String]]) {
        var cache = sliderContentCache
        cache["\(sliderID)"] = items
        sliderContentCache = cache
        cacheTimestamp = Date() // Update timestamp
        print("💾 Cached \(items.count) items for slider \(sliderID)")
    }

    /// Clear all cached content
    func clearCache() {
        sliderContentCache = [:]
        cacheTimestamp = nil
        print("🗑️ Cleared TopShelf cache")
    }

    // MARK: - Initialization

    private init() {
        self.userDefaults = UserDefaults(suiteName: appGroupID)

        // Set defaults if not already set
        if userDefaults?.string(forKey: displayModeKey) == nil {
            userDefaults?.set(TopShelfDisplayMode.hero.rawValue, forKey: displayModeKey)
        }
        if userDefaults?.string(forKey: contentSourceKey) == nil {
            userDefaults?.set(TopShelfContentSource.trending.rawValue, forKey: contentSourceKey)
        }
        userDefaults?.synchronize()
    }

    // MARK: - Extension Notification

    /// Notify the TopShelf extension to reload content
    private func notifyExtension() {
        #if os(tvOS)
        TVTopShelfContentProvider.topShelfContentDidChange()
        #endif
    }

    /// Force reload TopShelf content (call this from the app when settings change)
    func reloadTopShelf() {
        notifyExtension()
    }

    // MARK: - Slider Filtering

    /// Slider types that are NOT supported in TopShelf
    /// (genres, studios, networks - as per user requirement)
    static let unsupportedSliderTypes: Set<Int> = [
        6,  // movieGenres
        8,  // studios
        10, // tvGenres
        12  // networks
    ]

    /// Check if a slider type is supported for TopShelf
    static func isSliderTypeSupported(_ type: Int) -> Bool {
        return !unsupportedSliderTypes.contains(type)
    }

    // MARK: - Migration Helpers

    /// Migrate from legacy contentSource to new slider system
    func migrateLegacySettings() {
        // If we already have sliders configured, skip migration
        guard selectedSliders.isEmpty else { return }

        // Map legacy source to slider config
        let legacyMapping: [TopShelfContentSource: TopShelfSliderConfig] = [
            .trending: TopShelfSliderConfig(id: -1, title: "Trending", type: 4),
            .popularMovies: TopShelfSliderConfig(id: -2, title: "Popular Movies", type: 5),
            .popularTV: TopShelfSliderConfig(id: -3, title: "Popular TV", type: 9),
            .watchlist: TopShelfSliderConfig(id: -4, title: "Watchlist", type: 3)
        ]

        if let migrated = legacyMapping[contentSource] {
            selectedSliders = [migrated]
        }
    }
}
