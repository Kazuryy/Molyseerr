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

/// TopShelf content source
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
    private let contentSourceKey = "topshelf_content_source"

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
}
