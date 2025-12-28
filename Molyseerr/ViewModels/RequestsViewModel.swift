//
//  RequestsViewModel.swift
//  Molyseerr
//
//  Created by Claude on 28/12/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class RequestsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var requests: [MediaRequest] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedFilter: RequestFilter = .all
    @Published var hasMorePages: Bool = true

    // MARK: - Private Properties
    private var currentPage: Int = 1
    private let pageSize: Int = 20
    private var totalPages: Int = 1

    // Cache for media details (tmdbId -> title)
    private var mediaTitles: [Int: String] = [:]
    // Cache for media posters (tmdbId -> posterPath)
    private var mediaPosters: [Int: String] = [:]

    // MARK: - Fetch Requests
    func fetchRequests(refresh: Bool = false) async {
        if refresh {
            currentPage = 1
            requests.removeAll()
        }

        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let response = try await SeerrService.shared.getRequestList(
                filter: selectedFilter.rawValue,
                sort: "added",
                take: pageSize,
                skip: (currentPage - 1) * pageSize
            )

            // Fetch titles for media that we don't have cached BEFORE updating the requests list
            await fetchMissingTitles(for: response.results)

            // Update requests list AFTER titles are fetched
            if refresh {
                requests = response.results
            } else {
                requests.append(contentsOf: response.results)
            }

            // Update pagination info
            totalPages = response.pageInfo.pages
            hasMorePages = currentPage < totalPages

            isLoading = false
        } catch {
            errorMessage = "Failed to load requests: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Load More (Pagination)
    func loadMore() async {
        guard hasMorePages, !isLoading else { return }
        currentPage += 1
        await fetchRequests()
    }

    // MARK: - Refresh
    func refresh() async {
        await fetchRequests(refresh: true)
    }

    // MARK: - Apply Filter
    func applyFilter(_ filter: RequestFilter) async {
        guard selectedFilter != filter else { return }
        selectedFilter = filter
        await fetchRequests(refresh: true)
    }

    // MARK: - Cancel Request
    func cancelRequest(id: Int) async -> Bool {
        do {
            try await SeerrService.shared.deleteRequest(id: id)
            // Remove from local list
            requests.removeAll { $0.id == id }
            return true
        } catch {
            errorMessage = "Failed to cancel request: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Get Media Title
    func getMediaTitle(for request: MediaRequest) -> String {
        guard let media = request.media else { return "Unknown" }

        // Return cached title if available
        if let cachedTitle = mediaTitles[media.tmdbId] {
            return cachedTitle
        }

        // Fallback to original title or unknown
        return media.originalTitle ?? "Unknown"
    }

    // MARK: - Get Media Poster
    func getMediaPoster(for request: MediaRequest) -> String? {
        guard let media = request.media else { return nil }

        // Return cached poster if available, or use MediaInfo's posterPath directly
        return mediaPosters[media.tmdbId] ?? media.posterPath
    }

    // MARK: - Private Helpers
    private func fetchMissingTitles(for requests: [MediaRequest]) async {
        // Collect unique media items that need titles fetched
        let mediaToFetch = requests.compactMap { $0.media }
            .filter { mediaTitles[$0.tmdbId] == nil && $0.tmdbId > 0 }

        guard !mediaToFetch.isEmpty else {
            return
        }

        // Fetch titles and posters in parallel
        await withTaskGroup(of: (Int, String?, String?).self) { group in
            for media in mediaToFetch {
                group.addTask {
                    await self.fetchMediaDetails(tmdbId: media.tmdbId, mediaType: media.mediaType)
                }
            }

            // Collect results
            for await (tmdbId, title, posterPath) in group {
                if let title = title {
                    self.mediaTitles[tmdbId] = title
                }
                if let posterPath = posterPath {
                    self.mediaPosters[tmdbId] = posterPath
                }
            }
        }
    }

    private func fetchMediaDetails(tmdbId: Int, mediaType: MediaType) async -> (Int, String?, String?) {
        do {
            // Use TMDB API directly since Seerr API doesn't return posterPath
            if mediaType == .movie {
                let details = try await TMDBService.shared.getMovieDetails(id: tmdbId)
                return (tmdbId, details.title, details.posterPath)
            } else {
                let details = try await TMDBService.shared.getTVDetails(id: tmdbId)
                return (tmdbId, details.name, details.posterPath)
            }
        } catch {
            return (tmdbId, nil, nil)
        }
    }
}
