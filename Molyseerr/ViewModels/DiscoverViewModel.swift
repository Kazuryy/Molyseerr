//
//  DiscoverViewModel.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing Discover page sliders
/// Fetches slider configuration from server and manages slider content dynamically
/// Matches Seerr web app behavior: only displays enabled sliders in admin-configured order
@MainActor
class DiscoverViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Array of all slider configurations from server
    @Published var allSliders: [DiscoverSlider] = []

    /// Filtered array of enabled sliders in correct order (respecting feature flags)
    var enabledSliders: [DiscoverSlider] {
        let flags = FeatureFlagsManager.shared.flags
        return allSliders
            .filter { $0.enabled }
            .filterByFeatureFlags(flags)
            .sorted { $0.order < $1.order }
    }

    /// Loading state indicator
    @Published var isLoading = false

    /// Error message for user display
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let service = SeerrService.shared

    // MARK: - Initialization

    init() {
        // ViewModel initializes empty, call fetchSliders() to load configuration
    }

    // MARK: - Public Methods

    /// Fetches slider configuration from server
    /// - Parameter refresh: If true, clears existing data before fetching
    func fetchSliders(refresh: Bool = false) async {
        // Prevent multiple simultaneous requests
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        if refresh {
            allSliders = []
        }

        do {
            let sliders = try await service.getDiscoverSliders()
            allSliders = sliders

            print("📊 Loaded \(sliders.count) sliders from server")
            print("   ✅ Enabled: \(enabledSliders.count)")
            print("   ❌ Disabled: \(sliders.count - enabledSliders.count)")

            isLoading = false
        } catch {
            handleError(error)
        }
    }

    /// Refreshes the slider configuration (pull-to-refresh)
    func refresh() async {
        await fetchSliders(refresh: true)
    }

    // MARK: - Private Methods

    /// Handles errors and sets user-friendly error messages
    /// - Parameter error: The error to handle
    private func handleError(_ error: Error) {
        isLoading = false

        if let seerrError = error as? SeerrError {
            switch seerrError {
            case .unauthorized:
                errorMessage = "Authentication failed. Please check your credentials."
            case .notFound:
                errorMessage = "Slider configuration not found."
            case .serverError:
                errorMessage = "Server error. Please try again later."
            case .networkError(let underlyingError):
                errorMessage = "Network error: \(underlyingError.localizedDescription)"
            case .decodingError(let underlyingError):
                errorMessage = "Failed to load sliders: \(underlyingError.localizedDescription)"
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
