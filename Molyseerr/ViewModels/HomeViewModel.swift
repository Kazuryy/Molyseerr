//
//  HomeViewModel.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import Foundation
import Combine

/// Home page ViewModel
/// Manages multiple discovery sliders (Trending, Popular Movies, Popular TV, Upcoming)
/// Reference: APPLE_TV_DESIGN_REFERENCE.md + Seerr discover page patterns
@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Hero banner featured item (first trending item)
    @Published var featuredItem: MediaResult?

    /// Trending content
    @Published var trendingItems: [MediaResult] = []

    /// Popular movies
    @Published var popularMovies: [MediaResult] = []

    /// Popular TV shows
    @Published var popularTV: [MediaResult] = []

    /// Upcoming movies
    @Published var upcomingMovies: [MediaResult] = []

    /// Loading states for each section
    @Published var isTrendingLoading: Bool = false
    @Published var isPopularMoviesLoading: Bool = false
    @Published var isPopularTVLoading: Bool = false
    @Published var isUpcomingLoading: Bool = false

    /// Global error message (shows if initial load fails)
    @Published var errorMessage: String?

    /// Is initial content loaded
    @Published var isInitialLoadComplete: Bool = false

    // MARK: - Private Properties

    private let seerrService: SeerrService
    private var cancellables = Set<AnyCancellable>()

    // Pagination
    private var trendingPage: Int = 1
    private var popularMoviesPage: Int = 1
    private var popularTVPage: Int = 1
    private var upcomingPage: Int = 1

    // MARK: - Initialization

    init(seerrService: SeerrService) {
        self.seerrService = seerrService
    }

    convenience init() {
        self.init(seerrService: SeerrService.shared)
    }

    // MARK: - Public Methods

    /// Load all initial content
    func loadInitialContent() async {
        guard !isInitialLoadComplete else { return }

        errorMessage = nil

        // Load all sections in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadTrending() }
            group.addTask { await self.loadPopularMovies() }
            group.addTask { await self.loadPopularTV() }
            group.addTask { await self.loadUpcoming() }
        }

        isInitialLoadComplete = true
    }

    /// Refresh all content
    func refresh() async {
        // Reset pages
        trendingPage = 1
        popularMoviesPage = 1
        popularTVPage = 1
        upcomingPage = 1

        // Clear existing data
        trendingItems = []
        popularMovies = []
        popularTV = []
        upcomingMovies = []
        featuredItem = nil
        isInitialLoadComplete = false

        // Reload
        await loadInitialContent()
    }

    // MARK: - Private Methods

    /// Load trending content
    private func loadTrending() async {
        guard !isTrendingLoading else { return }

        isTrendingLoading = true
        defer { isTrendingLoading = false }

        do {
            let response = try await seerrService.getTrending(page: trendingPage)
            trendingItems.append(contentsOf: response.results)

            // Set featured item to first trending item
            if featuredItem == nil, let first = response.results.first {
                featuredItem = first
            }
        } catch {
            handleError(error, section: "Trending")
        }
    }

    /// Load popular movies
    private func loadPopularMovies() async {
        guard !isPopularMoviesLoading else { return }

        isPopularMoviesLoading = true
        defer { isPopularMoviesLoading = false }

        do {
            let response = try await seerrService.getPopularMovies(page: popularMoviesPage)
            popularMovies.append(contentsOf: response.results)
        } catch {
            handleError(error, section: "Popular Movies")
        }
    }

    /// Load popular TV shows
    private func loadPopularTV() async {
        guard !isPopularTVLoading else { return }

        isPopularTVLoading = true
        defer { isPopularTVLoading = false }

        do {
            let response = try await seerrService.getPopularTV(page: popularTVPage)
            popularTV.append(contentsOf: response.results)
        } catch {
            handleError(error, section: "Popular TV Shows")
        }
    }

    /// Load upcoming movies
    private func loadUpcoming() async {
        guard !isUpcomingLoading else { return }

        isUpcomingLoading = true
        defer { isUpcomingLoading = false }

        do {
            let response = try await seerrService.getUpcomingMovies(page: upcomingPage)
            upcomingMovies.append(contentsOf: response.results)
        } catch {
            handleError(error, section: "Upcoming Movies")
        }
    }

    /// Handle errors
    private func handleError(_ error: Error, section: String) {
        print("❌ Error loading \(section): \(error)")

        // Only set global error if it's the initial load
        if !isInitialLoadComplete {
            if let seerrError = error as? SeerrError {
                errorMessage = mapSeerrError(seerrError, section: section)
            } else {
                errorMessage = "Failed to load \(section): \(error.localizedDescription)"
            }
        }
    }

    /// Map SeerrError to user-friendly message
    private func mapSeerrError(_ error: SeerrError, section: String) -> String {
        switch error {
        case .invalidURL:
            return "Invalid server URL configuration."
        case .unauthorized:
            return "Unauthorized. Please check your API key."
        case .forbidden:
            return "Access forbidden. You may not have permission."
        case .notFound:
            return "\(section) not found."
        case .serverError:
            return "Server error. Please try again later."
        case .invalidResponse:
            return "Invalid response from server."
        case .decodingError:
            return "Failed to process \(section) data."
        case .networkError(let underlyingError):
            return "Network error: \(underlyingError.localizedDescription)"
        case .httpError(let statusCode, let message):
            if let message = message {
                return "Error \(statusCode): \(message)"
            }
            return "HTTP error: \(statusCode)"
        case .unknown:
            return "An unknown error occurred while loading \(section)."
        case .notImplemented:
            return "This feature is not yet implemented."
        case .configurationError(let message):
            return message
        }
    }
}
