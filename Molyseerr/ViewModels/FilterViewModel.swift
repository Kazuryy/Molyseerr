//
//  FilterViewModel.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI
import Combine

/// Filter media type for discovery
enum FilterMediaType: String {
    case movie
    case tv
}

/// Sort options for discover pages
enum SortOption: String, CaseIterable {
    case popularityDesc = "popularity.desc"
    case popularityAsc = "popularity.asc"
    case releaseDateDesc = "releaseDate.desc"  // Movies: primaryReleaseDate, TV: firstAirDate
    case releaseDateAsc = "releaseDate.asc"
    case ratingDesc = "voteAverage.desc"
    case ratingAsc = "voteAverage.asc"
    case titleAsc = "title.asc"
    case titleDesc = "title.desc"

    var displayName: String {
        switch self {
        case .popularityDesc: return "Popularity (High to Low)"
        case .popularityAsc: return "Popularity (Low to High)"
        case .releaseDateDesc: return "Release Date (Newest)"
        case .releaseDateAsc: return "Release Date (Oldest)"
        case .ratingDesc: return "Rating (High to Low)"
        case .ratingAsc: return "Rating (Low to High)"
        case .titleAsc: return "Title (A-Z)"
        case .titleDesc: return "Title (Z-A)"
        }
    }
}

/// TV Series status options
enum SeriesStatus: Int, CaseIterable {
    case returningSeries = 0
    case planned = 1
    case inProduction = 2
    case ended = 3
    case cancelled = 4
    case pilot = 5

    var displayName: String {
        switch self {
        case .returningSeries: return "Returning Series"
        case .planned: return "Planned"
        case .inProduction: return "In Production"
        case .ended: return "Ended"
        case .cancelled: return "Cancelled"
        case .pilot: return "Pilot"
        }
    }
}

/// Filter state for Movies or TV Shows discovery
@MainActor
class FilterViewModel: ObservableObject {
    // MARK: - Media Type
    let mediaType: FilterMediaType

    // MARK: - Sort
    @Published var sortBy: SortOption = .popularityDesc

    // MARK: - Date Range
    @Published var releaseDateFrom: Date?
    @Published var releaseDateTo: Date?

    // MARK: - Genres
    @Published var selectedGenres: Set<Int> = []
    @Published var availableGenres: [Genre] = []

    // MARK: - Keywords
    @Published var includeKeywords: Set<Int> = []
    @Published var excludeKeywords: Set<Int> = []

    // MARK: - Language
    @Published var selectedLanguage: String?

    // MARK: - Runtime (in minutes)
    @Published var runtimeMin: Int = 0
    @Published var runtimeMax: Int = 400
    @Published var isRuntimeFilterActive: Bool = false

    // MARK: - Rating (TMDB Vote Average 0-10)
    @Published var ratingMin: Double = 0.0
    @Published var ratingMax: Double = 10.0
    @Published var isRatingFilterActive: Bool = false

    // MARK: - Vote Count
    @Published var voteCountMin: Int = 0
    @Published var voteCountMax: Int = 1000
    @Published var isVoteCountFilterActive: Bool = false

    // MARK: - Certification (Content Rating)
    @Published var certification: String?
    @Published var certificationCountry: String = "US"

    // MARK: - Streaming Services
    @Published var watchProviders: Set<Int> = []
    @Published var watchRegion: String = "US"

    // MARK: - Movie-Specific
    @Published var selectedStudio: Int?

    // MARK: - TV-Specific
    @Published var selectedNetwork: Int?
    @Published var selectedStatuses: Set<SeriesStatus> = []

    // MARK: - State
    @Published var isLoading = false

    private let service = SeerrService.shared

    // MARK: - Initialization
    init(mediaType: FilterMediaType) {
        self.mediaType = mediaType
    }

    // MARK: - Computed Properties

    /// Count of active filters
    var activeFilterCount: Int {
        var count = 0

        if sortBy != .popularityDesc { count += 1 }
        if releaseDateFrom != nil || releaseDateTo != nil { count += 1 }
        if !selectedGenres.isEmpty { count += 1 }
        if !includeKeywords.isEmpty { count += 1 }
        if !excludeKeywords.isEmpty { count += 1 }
        if selectedLanguage != nil { count += 1 }
        if isRuntimeFilterActive { count += 1 }
        if isRatingFilterActive { count += 1 }
        if isVoteCountFilterActive { count += 1 }
        if certification != nil { count += 1 }
        if !watchProviders.isEmpty { count += 1 }
        if selectedStudio != nil { count += 1 }
        if selectedNetwork != nil { count += 1 }
        if !selectedStatuses.isEmpty { count += 1 }

        return count
    }

    /// Check if any filters are active
    var hasActiveFilters: Bool {
        return activeFilterCount > 0
    }

    // MARK: - Methods

    /// Load available genres for the media type
    func loadGenres() async {
        isLoading = true

        do {
            if mediaType == .movie {
                availableGenres = try await service.getMovieGenres()
            } else {
                availableGenres = try await service.getTVGenres()
            }
        } catch {
            print("Failed to load genres: \(error)")
        }

        isLoading = false
    }

    /// Clear all active filters
    func clearFilters() {
        sortBy = .popularityDesc
        releaseDateFrom = nil
        releaseDateTo = nil
        selectedGenres.removeAll()
        includeKeywords.removeAll()
        excludeKeywords.removeAll()
        selectedLanguage = nil
        runtimeMin = 0
        runtimeMax = 400
        isRuntimeFilterActive = false
        ratingMin = 0.0
        ratingMax = 10.0
        isRatingFilterActive = false
        voteCountMin = 0
        voteCountMax = 1000
        isVoteCountFilterActive = false
        certification = nil
        watchProviders.removeAll()
        selectedStudio = nil
        selectedNetwork = nil
        selectedStatuses.removeAll()
    }

    // MARK: - API Query Building

    /// Build query parameters for discoverMovies API call
    func buildMovieQueryParameters(page: Int = 1) -> (
        page: Int,
        sortBy: String,
        genre: String?,
        keywords: String?,
        excludeKeywords: String?,
        studio: String?,
        primaryReleaseDateGte: String?,
        primaryReleaseDateLte: String?,
        language: String?,
        watchRegion: String?,
        watchProviders: String?,
        withRuntimeGte: Int?,
        withRuntimeLte: Int?,
        voteAverageGte: Double?,
        voteAverageLte: Double?,
        voteCountGte: Int?,
        voteCountLte: Int?,
        certification: String?,
        certificationGte: String?,
        certificationLte: String?,
        certificationCountry: String?
    ) {
        return (
            page: page,
            sortBy: sortBy.rawValue,
            genre: selectedGenres.isEmpty ? nil : selectedGenres.map { String($0) }.joined(separator: ","),
            keywords: includeKeywords.isEmpty ? nil : includeKeywords.map { String($0) }.joined(separator: ","),
            excludeKeywords: excludeKeywords.isEmpty ? nil : excludeKeywords.map { String($0) }.joined(separator: ","),
            studio: selectedStudio.map { String($0) },
            primaryReleaseDateGte: releaseDateFrom.map { formatDate($0) },
            primaryReleaseDateLte: releaseDateTo.map { formatDate($0) },
            language: selectedLanguage,
            watchRegion: watchProviders.isEmpty ? nil : watchRegion,
            watchProviders: watchProviders.isEmpty ? nil : watchProviders.map { String($0) }.joined(separator: "|"),
            withRuntimeGte: isRuntimeFilterActive ? runtimeMin : nil,
            withRuntimeLte: isRuntimeFilterActive ? runtimeMax : nil,
            voteAverageGte: isRatingFilterActive ? ratingMin : nil,
            voteAverageLte: isRatingFilterActive ? ratingMax : nil,
            voteCountGte: isVoteCountFilterActive ? voteCountMin : nil,
            voteCountLte: isVoteCountFilterActive ? voteCountMax : nil,
            certification: certification,
            certificationGte: nil, // TODO: Implement certification range mode
            certificationLte: nil,
            certificationCountry: certification != nil ? certificationCountry : nil
        )
    }

    /// Build query parameters for discoverTV API call
    func buildTVQueryParameters(page: Int = 1) -> (
        page: Int,
        sortBy: String,
        genre: String?,
        keywords: String?,
        excludeKeywords: String?,
        network: String?,
        firstAirDateGte: String?,
        firstAirDateLte: String?,
        language: String?,
        watchRegion: String?,
        watchProviders: String?,
        withRuntimeGte: Int?,
        withRuntimeLte: Int?,
        voteAverageGte: Double?,
        voteAverageLte: Double?,
        voteCountGte: Int?,
        voteCountLte: Int?,
        certification: String?,
        certificationGte: String?,
        certificationLte: String?,
        certificationCountry: String?,
        status: String?
    ) {
        return (
            page: page,
            sortBy: sortBy.rawValue,
            genre: selectedGenres.isEmpty ? nil : selectedGenres.map { String($0) }.joined(separator: ","),
            keywords: includeKeywords.isEmpty ? nil : includeKeywords.map { String($0) }.joined(separator: ","),
            excludeKeywords: excludeKeywords.isEmpty ? nil : excludeKeywords.map { String($0) }.joined(separator: ","),
            network: selectedNetwork.map { String($0) },
            firstAirDateGte: releaseDateFrom.map { formatDate($0) },
            firstAirDateLte: releaseDateTo.map { formatDate($0) },
            language: selectedLanguage,
            watchRegion: watchProviders.isEmpty ? nil : watchRegion,
            watchProviders: watchProviders.isEmpty ? nil : watchProviders.map { String($0) }.joined(separator: "|"),
            withRuntimeGte: isRuntimeFilterActive ? runtimeMin : nil,
            withRuntimeLte: isRuntimeFilterActive ? runtimeMax : nil,
            voteAverageGte: isRatingFilterActive ? ratingMin : nil,
            voteAverageLte: isRatingFilterActive ? ratingMax : nil,
            voteCountGte: isVoteCountFilterActive ? voteCountMin : nil,
            voteCountLte: isVoteCountFilterActive ? voteCountMax : nil,
            certification: certification,
            certificationGte: nil,
            certificationLte: nil,
            certificationCountry: certification != nil ? certificationCountry : nil,
            status: selectedStatuses.isEmpty ? nil : selectedStatuses.map { String($0.rawValue) }.joined(separator: ",")
        )
    }

    // MARK: - Private Helpers

    /// Format date to YYYY-MM-DD for API
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
