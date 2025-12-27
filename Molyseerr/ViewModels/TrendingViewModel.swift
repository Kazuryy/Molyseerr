//
//  TrendingViewModel.swift
//  Molyseerr
//
//  Created by Kazuryy on 24/12/2025.
//

import Foundation
import SwiftUI
import Combine

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
            case .serverError:
                errorMessage = "Server error. Please try again later."
            case .networkError(let underlyingError):
                errorMessage = "Network error: \(underlyingError.localizedDescription)"
            case .decodingError(let underlyingError):
                errorMessage = "Failed to load content: \(underlyingError.localizedDescription)"
            case .invalidURL:
                errorMessage = "Invalid server URL."
            case .invalidResponse:
                errorMessage = "Invalid response from server."
            case .forbidden:
                errorMessage = "Access forbidden. Please check your permissions."
            case .httpError(let statusCode, let message):
                errorMessage = "HTTP error \(statusCode): \(message ?? "Unknown error")"
            case .unknown:
                errorMessage = "An unknown error occurred."
            case .notImplemented:
                errorMessage = "This feature is not yet implemented."
            case .configurationError(let message):
                errorMessage = message
            }
        } else {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}
