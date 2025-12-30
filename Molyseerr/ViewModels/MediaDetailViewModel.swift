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
    private let tmdbService: TMDBService

    // MARK: - Initialization

    nonisolated init(seerrService: SeerrService? = nil, tmdbService: TMDBService? = nil) {
        self.seerrService = seerrService ?? SeerrService.shared
        self.tmdbService = tmdbService ?? TMDBService.shared
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
                // Load from both Seerr (for full details + mediaInfo) and TMDB (for images if missing)
                async let seerrData = try seerrService.getMovieDetails(id: id)
                async let tmdbData = try? tmdbService.getMovieDetails(id: id)

                var details = try await seerrData
                let tmdb = await tmdbData

                // If Seerr didn't return images or rating, use TMDB's as fallback
                if details.backdropPath == nil || details.posterPath == nil || details.voteAverage == nil {
                    details = MovieDetails(
                        id: details.id,
                        imdbId: details.imdbId,
                        adult: details.adult,
                        backdropPath: details.backdropPath ?? tmdb?.backdropPath,
                        posterPath: details.posterPath ?? tmdb?.posterPath,
                        budget: details.budget,
                        genres: details.genres,
                        homepage: details.homepage,
                        relatedVideos: details.relatedVideos,
                        originalLanguage: details.originalLanguage,
                        originalTitle: details.originalTitle,
                        overview: details.overview,
                        popularity: details.popularity,
                        productionCompanies: details.productionCompanies,
                        releaseDate: details.releaseDate,
                        revenue: details.revenue,
                        runtime: details.runtime,
                        status: details.status,
                        tagline: details.tagline,
                        title: details.title,
                        video: details.video,
                        voteAverage: details.voteAverage ?? tmdb?.voteAverage,
                        voteCount: details.voteCount ?? tmdb?.voteCount,
                        credits: details.credits,
                        mediaInfo: details.mediaInfo
                    )
                }

                movieDetails = details
            case .tv:
                // Load from both Seerr (for full details + mediaInfo) and TMDB (for images if missing)
                async let seerrData = try seerrService.getTVDetails(id: id)
                async let tmdbData = try? tmdbService.getTVDetails(id: id)

                var details = try await seerrData
                let tmdb = await tmdbData

                // If Seerr didn't return images or rating, use TMDB's as fallback
                if details.backdropPath == nil || details.posterPath == nil || details.voteAverage == nil {
                    details = TVDetails(
                        id: details.id,
                        backdropPath: details.backdropPath ?? tmdb?.backdropPath,
                        posterPath: details.posterPath ?? tmdb?.posterPath,
                        createdBy: details.createdBy,
                        episodeRunTime: details.episodeRunTime,
                        firstAirDate: details.firstAirDate,
                        genres: details.genres,
                        homepage: details.homepage,
                        inProduction: details.inProduction,
                        languages: details.languages,
                        lastAirDate: details.lastAirDate,
                        lastEpisodeToAir: details.lastEpisodeToAir,
                        name: details.name,
                        nextEpisodeToAir: details.nextEpisodeToAir,
                        networks: details.networks,
                        numberOfEpisodes: details.numberOfEpisodes,
                        numberOfSeasons: details.numberOfSeasons,
                        originCountry: details.originCountry,
                        originalLanguage: details.originalLanguage,
                        originalName: details.originalName,
                        overview: details.overview,
                        popularity: details.popularity,
                        productionCompanies: details.productionCompanies,
                        seasons: details.seasons,
                        status: details.status,
                        tagline: details.tagline,
                        type: details.type,
                        voteAverage: details.voteAverage ?? tmdb?.voteAverage,
                        voteCount: details.voteCount ?? tmdb?.voteCount,
                        credits: details.credits,
                        mediaInfo: details.mediaInfo
                    )
                }

                tvDetails = details
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ MediaDetailViewModel error: \(error)")
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
