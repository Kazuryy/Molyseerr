//
//  DiscoverCacheManager.swift
//  Molyseerr
//
//  Created by Claude on 03/01/2026.
//

import Foundation

/// Manages persistent caching of Discover page data for instant loading
/// Stores slider content in UserDefaults for quick access on app launch
actor DiscoverCacheManager {
    static let shared = DiscoverCacheManager()

    private let userDefaults = UserDefaults.standard
    private let cachePrefix = "discover_cache_"
    private let cacheVersionKey = "cache_version"
    private let currentCacheVersion = 1  // Increment this to invalidate old caches

    private init() {
        // Check if cache version matches, clear if not
        if userDefaults.integer(forKey: cacheVersionKey) != currentCacheVersion {
            clearAllCache()
            userDefaults.set(currentCacheVersion, forKey: cacheVersionKey)
        }
    }

    // MARK: - Cache Operations

    /// Save slider content to cache
    func cacheSliderContent(_ items: [MediaResult], for sliderType: String) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(items)
            userDefaults.set(data, forKey: cacheKey(for: sliderType))
            print("✅ Cached \(items.count) items for slider: \(sliderType)")
        } catch {
            print("❌ Failed to cache slider \(sliderType): \(error)")
        }
    }

    /// Load slider content from cache
    func loadCachedSliderContent(for sliderType: String) -> [MediaResult]? {
        guard let data = userDefaults.data(forKey: cacheKey(for: sliderType)) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let items = try decoder.decode([MediaResult].self, from: data)
            print("✅ Loaded \(items.count) cached items for slider: \(sliderType)")
            return items
        } catch {
            print("❌ Failed to load cached slider \(sliderType): \(error)")
            return nil
        }
    }

    /// Check if cache exists for a slider
    func hasCachedContent(for sliderType: String) -> Bool {
        return userDefaults.data(forKey: cacheKey(for: sliderType)) != nil
    }

    /// Clear cache for a specific slider
    func clearCache(for sliderType: String) {
        userDefaults.removeObject(forKey: cacheKey(for: sliderType))
    }

    /// Clear all cached sliders
    func clearAllCache() {
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys where key.hasPrefix(cachePrefix) {
            userDefaults.removeObject(forKey: key)
        }
        print("🗑️ Cleared all discover cache")
    }

    // MARK: - Private Helpers

    private func cacheKey(for sliderType: String) -> String {
        return "\(cachePrefix)\(sliderType)"
    }
}
