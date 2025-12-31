//
//  SearchViewModel.swift
//  Molyseerr
//
//  Created by Claude on 31/12/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchResults: [MediaResult] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchQuery: String = ""
    @Published var hasMorePages: Bool = false
    @Published var isSearching: Bool = false

    // MARK: - Private Properties
    private var currentPage: Int = 1
    private var totalPages: Int = 1
    private var searchTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?

    // Debounce delay (300ms as per Seerr webapp)
    private let debounceDelay: TimeInterval = 0.3

    // MARK: - Search Methods

    /// Perform search with debouncing
    /// This method is called when the user types in the search field
    func performSearch(query: String) {
        // Update search query
        searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Cancel previous debounce task
        debounceTask?.cancel()

        // If query is empty, clear results
        guard !searchQuery.isEmpty else {
            clearResults()
            return
        }

        // Show searching state
        isSearching = true

        // Debounce the search
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(debounceDelay * 1_000_000_000))

            // Check if task was cancelled
            guard !Task.isCancelled else { return }

            // Perform the actual search
            await search(query: searchQuery, refresh: true)
            isSearching = false
        }
    }

    /// Actual search implementation
    /// Can be called directly when user submits the search
    func search(query: String, refresh: Bool = true) async {
        // Update search query
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        searchQuery = trimmedQuery

        // Don't search if query is empty
        guard !trimmedQuery.isEmpty else {
            clearResults()
            return
        }

        // Cancel previous search task
        searchTask?.cancel()

        if refresh {
            currentPage = 1
            searchResults.removeAll()
        }

        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        searchTask = Task {
            do {
                let response = try await SeerrService.shared.search(
                    query: trimmedQuery,
                    page: currentPage
                )

                // Check if task was cancelled
                guard !Task.isCancelled else {
                    isLoading = false
                    return
                }

                // Update results
                if refresh {
                    searchResults = response.results
                } else {
                    searchResults.append(contentsOf: response.results)
                }

                // Update pagination info
                totalPages = response.totalPages
                hasMorePages = currentPage < totalPages

                isLoading = false
            } catch {
                // Check if task was cancelled
                guard !Task.isCancelled else {
                    isLoading = false
                    return
                }

                errorMessage = "Failed to search: \(error.localizedDescription)"
                isLoading = false
            }
        }

        await searchTask?.value
    }

    // MARK: - Load More (Pagination)
    func loadMore() async {
        guard hasMorePages, !isLoading, !searchQuery.isEmpty else { return }
        currentPage += 1
        await search(query: searchQuery)
    }

    // MARK: - Refresh
    func refresh() async {
        guard !searchQuery.isEmpty else { return }
        await search(query: searchQuery, refresh: true)
    }

    // MARK: - Clear Results
    func clearResults() {
        searchTask?.cancel()
        debounceTask?.cancel()
        searchResults.removeAll()
        currentPage = 1
        totalPages = 1
        hasMorePages = false
        errorMessage = nil
        isLoading = false
        isSearching = false
    }

    // MARK: - Special Search Patterns

    /// Check if the query uses special search patterns
    /// Patterns: tmdb:12345, imdb:tt1234567, tvdb:12345, year:2024
    func hasSpecialPattern(query: String) -> Bool {
        let patterns = [
            "^tmdb:\\d+",
            "^imdb:(tt|nm)\\d+",
            "^tvdb:\\d+",
            "year:\\d{4}"
        ]

        for pattern in patterns {
            if query.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }

        return false
    }
}
