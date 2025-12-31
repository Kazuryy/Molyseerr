//
//  WatchlistManager.swift
//  Molyseerr
//
//  Created by Claude on 31/12/2025.
//

import Foundation
import Combine

/// Manager for watchlist state and operations
/// Handles adding/removing items and tracking watchlist status
@MainActor
final class WatchlistManager: ObservableObject {

    // MARK: - Singleton

    static let shared = WatchlistManager()

    // MARK: - Published Properties

    /// Set of TMDB IDs currently in watchlist
    @Published private(set) var watchlistIds: Set<Int> = []

    /// Loading state for watchlist operations
    @Published var isLoading: Bool = false

    /// Error message if operation fails
    @Published var errorMessage: String?

    /// Success message for user feedback
    @Published var successMessage: String?

    // MARK: - Dependencies

    private let seerrService: SeerrService

    // MARK: - Initialization

    nonisolated init(seerrService: SeerrService = .shared) {
        self.seerrService = seerrService
    }

    // MARK: - Public Methods

    /// Check if media is in watchlist
    func isInWatchlist(_ tmdbId: Int) -> Bool {
        return watchlistIds.contains(tmdbId)
    }

    /// Load watchlist from server
    func loadWatchlist() async {
        isLoading = true
        errorMessage = nil

        do {
            let items = try await seerrService.getWatchlist(page: 1)
            watchlistIds = Set(items.compactMap { $0.tmdbId })
            print("⭐ Loaded watchlist: \(watchlistIds.count) items - IDs: \(watchlistIds)")
            isLoading = false
        } catch {
            print("⭐ Error loading watchlist: \(error)")
            errorMessage = "Failed to load watchlist: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Toggle watchlist status for a media item
    /// - Parameters:
    ///   - tmdbId: TMDB ID of the media
    ///   - mediaType: Type of media (movie or tv)
    ///   - title: Title of the media
    /// - Returns: New watchlist status (true if added, false if removed)
    @discardableResult
    func toggleWatchlist(tmdbId: Int, mediaType: MediaType, title: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        let isCurrentlyInWatchlist = watchlistIds.contains(tmdbId)
        print("⭐ Toggle watchlist for tmdbId: \(tmdbId), currently in watchlist: \(isCurrentlyInWatchlist)")
        print("⭐ Current watchlist IDs: \(watchlistIds)")

        do {
            if isCurrentlyInWatchlist {
                // Remove from watchlist
                print("⭐ Removing tmdbId \(tmdbId) from watchlist...")
                try await seerrService.removeFromWatchlist(tmdbId: tmdbId)
                watchlistIds.remove(tmdbId)
                print("⭐ Successfully removed! New watchlist IDs: \(watchlistIds)")
                successMessage = "Removed from watchlist"
                isLoading = false
                return false
            } else {
                // Add to watchlist
                print("⭐ Adding tmdbId \(tmdbId) to watchlist...")
                let _ = try await seerrService.addToWatchlist(
                    tmdbId: tmdbId,
                    mediaType: mediaType,
                    title: title
                )
                watchlistIds.insert(tmdbId)
                print("⭐ Successfully added! New watchlist IDs: \(watchlistIds)")
                successMessage = "Added to watchlist"
                isLoading = false
                return true
            }
        } catch {
            print("⭐ Error toggling watchlist: \(error)")
            errorMessage = "Failed to update watchlist: \(error.localizedDescription)"
            isLoading = false
            return isCurrentlyInWatchlist
        }
    }

    /// Add media to watchlist
    /// - Parameters:
    ///   - tmdbId: TMDB ID of the media
    ///   - mediaType: Type of media (movie or tv)
    ///   - title: Title of the media
    func addToWatchlist(tmdbId: Int, mediaType: MediaType, title: String) async {
        guard !watchlistIds.contains(tmdbId) else {
            // Already in watchlist
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            let _ = try await seerrService.addToWatchlist(
                tmdbId: tmdbId,
                mediaType: mediaType,
                title: title
            )
            watchlistIds.insert(tmdbId)
            successMessage = "Added to watchlist"
            isLoading = false
        } catch {
            errorMessage = "Failed to add to watchlist: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Remove media from watchlist
    /// - Parameter tmdbId: TMDB ID of the media
    func removeFromWatchlist(tmdbId: Int) async {
        guard watchlistIds.contains(tmdbId) else {
            // Not in watchlist
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            try await seerrService.removeFromWatchlist(tmdbId: tmdbId)
            watchlistIds.remove(tmdbId)
            successMessage = "Removed from watchlist"
            isLoading = false
        } catch {
            errorMessage = "Failed to remove from watchlist: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Clear success and error messages
    func clearMessages() {
        successMessage = nil
        errorMessage = nil
    }
}
