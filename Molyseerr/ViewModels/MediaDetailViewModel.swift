//
//  MediaDetailViewModel.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import Foundation
import Combine

/// ViewModel for media detail page
/// Loads full movie or TV show details from Seerr API
@MainActor
final class MediaDetailViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Loading state
    @Published var isLoading: Bool = false

    /// Error message if loading fails
    @Published var errorMessage: String?

    /// Movie details (if media is a movie)
    @Published var movieDetails: MovieDetails?

    /// TV show details (if media is a TV show)
    @Published var tvDetails: TVDetails?

    // MARK: - Dependencies

    private let seerrService: SeerrService

    // MARK: - Initialization

    init(seerrService: SeerrService = .shared) {
        self.seerrService = seerrService
    }

    // MARK: - Public Methods

    /// Load media details based on media type
    /// - Parameters:
    ///   - id: TMDB media ID
    ///   - mediaType: Either .movie or .tv
    func loadDetails(id: Int, mediaType: MediaType) async {
        isLoading = true
        errorMessage = nil
        movieDetails = nil
        tvDetails = nil

        do {
            switch mediaType {
            case .movie:
                movieDetails = try await seerrService.getMovieDetails(id: id)
            case .tv:
                tvDetails = try await seerrService.getTVDetails(id: id)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load details: \(error)")
        }

        isLoading = false
    }

    /// Convenience method to load from MediaResult
    func loadDetails(from mediaResult: MediaResult, refresh: Bool = false) async {
        await loadDetails(id: mediaResult.id, mediaType: mediaResult.mediaType)
    }

    // MARK: - Computed Properties

    /// Title (works for both movie and TV)
    var title: String {
        if let movie = movieDetails {
            return movie.displayTitle
        } else if let tv = tvDetails {
            return tv.displayName
        }
        return ""
    }

    /// Overview/synopsis
    var overview: String? {
        movieDetails?.overview ?? tvDetails?.overview
    }

    /// Backdrop path
    var backdropPath: String? {
        movieDetails?.backdropPath ?? tvDetails?.backdropPath
    }

    /// Poster path
    var posterPath: String? {
        movieDetails?.posterPath ?? tvDetails?.posterPath
    }

    /// Genres
    var genres: [Genre] {
        movieDetails?.genres ?? tvDetails?.genres ?? []
    }

    /// Media info (availability, request status)
    var mediaInfo: MediaInfo? {
        movieDetails?.mediaInfo ?? tvDetails?.mediaInfo
    }

    /// Vote average (rating)
    var voteAverage: Double? {
        movieDetails?.voteAverage ?? tvDetails?.voteAverage
    }

    /// Runtime (formatted)
    var runtime: String? {
        movieDetails?.formattedRuntime ?? tvDetails?.formattedRuntime
    }

    /// Release year
    var year: String? {
        movieDetails?.releaseYear ?? tvDetails?.firstAirYear
    }

    /// Cast members (top 10)
    var topCast: [Cast] {
        let allCast = movieDetails?.credits?.cast ?? tvDetails?.credits?.cast ?? []
        return Array(allCast.prefix(10))
    }

    /// Media type
    var mediaType: MediaType {
        if movieDetails != nil {
            return .movie
        } else if tvDetails != nil {
            return .tv
        }
        return .movie
    }

    /// Check if media is available
    var isAvailable: Bool {
        guard let mediaInfo = mediaInfo else { return false }
        return mediaInfo.status == .available
    }

    /// Check if media has pending request
    var hasPendingRequest: Bool {
        guard let mediaInfo = mediaInfo else { return false }
        return mediaInfo.status == .pending || mediaInfo.status == .processing
    }

    /// Check if media can be requested
    var canRequest: Bool {
        guard let mediaInfo = mediaInfo else { return true }
        return mediaInfo.status != .available && mediaInfo.status != .pending && mediaInfo.status != .processing
    }
}
