//
//  TrendingViewModel.swift
//  Molyseerr
//
//  Created by Ronan Jacques on 24/12/2025.
//

import Foundation
import SwiftUI

/// ViewModel for managing trending content display
/// Handles fetching, pagination, and state management for trending movies and TV shows
@MainActor
class TrendingViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Array of trending media items (movies and TV shows)
    @Published var trendingItems: [MediaResult] = []

    /// Loading state indicator
    @Published var isLoading = false

    /// Error message for user display
    @Published var errorMessage: String?

    /// Current page number for pagination
    @Published private(set) var currentPage = 1

    /// Total number of pages available
    @Published private(set) var totalPages = 1

    /// Indicates if there are more pages to load
    var hasMorePages: Bool {
        currentPage < totalPages
    }

    // MARK: - Private Properties

    private let service = SeerrService.shared

    // MARK: - Initialization

    init() {
        // ViewModel initializes empty, call fetchTrending() to load data
    }

    // MARK: - Public Methods

    /// Fetches the first page of trending content
    /// - Parameter refresh: If true, clears existing data before fetching
    func fetchTrending(refresh: Bool = false) async {
        // Prevent multiple simultaneous requests
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        if refresh {
            currentPage = 1
            trendingItems = []
        }

        do {
            let response = try await service.getTrending(page: currentPage)

            // Update trending items
            if refresh {
                trendingItems = response.results
            } else {
                trendingItems.append(contentsOf: response.results)
            }

            // Update pagination info
            currentPage = response.page
            totalPages = response.totalPages

            isLoading = false
        } catch {
            handleError(error)
        }
    }

    /// Loads the next page of trending content
    func loadNextPage() async {
        guard hasMorePages && !isLoading else { return }

        currentPage += 1
        await fetchTrending()
    }

    /// Refreshes the trending content (pull-to-refresh)
    func refresh() async {
        await fetchTrending(refresh: true)
    }

    // MARK: - Private Methods

    /// Handles errors and sets user-friendly error messages
    /// - Parameter error: The error to handle
    private func handleError(_ error: Error) {
        isLoading = false

        if let seerrError = error as? SeerrError {
            switch seerrError {
            case .unauthorized:
                errorMessage = "Authentication failed. Please check your API key."
            case .notFound:
                errorMessage = "Content not found."
            case .serverError(let message):
                errorMessage = "Server error: \(message)"
            case .networkError:
                errorMessage = "Network error. Please check your connection."
            case .decodingError:
                errorMessage = "Failed to load content. Please try again."
            case .invalidURL:
                errorMessage = "Invalid server URL."
            case .missingCredentials:
                errorMessage = "Missing API credentials. Please configure your Seerr server."
            }
        } else {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}
