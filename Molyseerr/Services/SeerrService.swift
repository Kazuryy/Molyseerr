//
//  SeerrService.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import Foundation
import Combine

/// Seerr API Service - Singleton
/// Uses async/await with URLSession as per TECH_RULES.md Section 1
/// Source: seerr-api.yml for all endpoints
final class SeerrService: ObservableObject {

    // MARK: - Singleton
    static let shared = SeerrService()

    // MARK: - Configuration
    /// API Key for authentication
    /// Managed by ConfigManager
    private var apiKey: String = ""

    /// Base URL for Seerr API
    /// Managed by ConfigManager
    private var baseURL: String = ""

    /// URL Session for network requests
    private let session: URLSession

    // MARK: - Initialization
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)

        // Configuration will be set via ConfigManager.configure() method
        // which calls setBaseURL() and setApiKey()
    }

    // MARK: - Configuration Methods

    /// Update API key
    func setApiKey(_ key: String) {
        self.apiKey = key
    }

    /// Update base URL
    func setBaseURL(_ url: String) {
        self.baseURL = url
    }

    // MARK: - Private Helpers

    /// Build full URL from path
    private func buildURL(path: String, queryItems: [URLQueryItem]? = nil) -> URL? {
        let fullPath = "\(baseURL)/api/v1\(path)"
        guard var components = URLComponents(string: fullPath) else {
            return nil
        }
        components.queryItems = queryItems
        return components.url
    }

    /// Create URL request with authentication headers
    private func createRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method

        // Authentication: X-Api-Key header (seerr-api.yml authentication)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return request
    }

    /// Perform network request and decode response
    private func performRequest<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem]? = nil,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        // Build URL
        guard let url = buildURL(path: path, queryItems: queryItems) else {
            throw SeerrError.invalidURL
        }

        // Create request
        var request = createRequest(url: url, method: method)
        if let body = body {
            request.httpBody = body
        }

        // Perform request
        let (data, response) = try await session.data(for: request)

        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SeerrError.invalidResponse
        }

        // Handle HTTP errors
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw SeerrError.unauthorized
        case 403:
            throw SeerrError.forbidden
        case 404:
            throw SeerrError.notFound
        case 500...599:
            throw SeerrError.serverError
        default:
            let message = String(data: data, encoding: .utf8)
            throw SeerrError.httpError(statusCode: httpResponse.statusCode, message: message)
        }

        // Decode response
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let result = try decoder.decode(T.self, from: data)
            return result
        } catch {
            throw SeerrError.decodingError(error)
        }
    }

    /// Perform network request with camelCase decoding (for /available endpoints)
    private func performRequestCamelCase<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem]? = nil,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        // Build URL
        guard let url = buildURL(path: path, queryItems: queryItems) else {
            throw SeerrError.invalidURL
        }

        // Create request
        var request = createRequest(url: url, method: method)
        if let body = body {
            request.httpBody = body
        }

        // Perform request
        let (data, response) = try await session.data(for: request)

        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SeerrError.invalidResponse
        }

        // Handle HTTP errors
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw SeerrError.unauthorized
        case 403:
            throw SeerrError.forbidden
        case 404:
            throw SeerrError.notFound
        case 500...599:
            throw SeerrError.serverError
        default:
            let message = String(data: data, encoding: .utf8)
            throw SeerrError.httpError(statusCode: httpResponse.statusCode, message: message)
        }

        // Decode response WITHOUT snake_case conversion (API returns camelCase)
        do {
            let decoder = JSONDecoder()
            // No keyDecodingStrategy - use keys as-is (camelCase)
            let result = try decoder.decode(T.self, from: data)
            return result
        } catch {
            print("❌ Decoding error for \(path): \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Response JSON: \(jsonString.prefix(500))")
            }
            throw SeerrError.decodingError(error)
        }
    }

    // MARK: - Discovery & Trending

    /// Get backdrop images for animated backgrounds
    /// Source: Seerr /backdrops endpoint - returns trending backdrop paths
    /// Used for login/settings page animated backgrounds
    /// - Returns: Array of TMDB backdrop paths (e.g., "/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg")
    func getBackdrops() async throws -> [String] {
        return try await performRequest(path: "/backdrops")
    }

    /// Get discover slider configuration from server
    /// Source: seerr-api.yml /settings/discover endpoint
    /// Returns array of slider configurations ordered by admin settings
    /// - Returns: Array of discover sliders (only enabled ones should be displayed)
    func getDiscoverSliders() async throws -> [DiscoverSlider] {
        return try await performRequest(path: "/settings/discover")
    }

    /// Get trending media (movies and TV shows)
    /// Source: seerr-api.yml /discover/trending endpoint
    /// - Parameters:
    ///   - page: Page number (default: 1)
    /// - Returns: Paginated response of mixed media results
    func getTrending(page: Int = 1) async throws -> PaginatedResponse<MediaResult> {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page))
        ]

        // First get the raw response to handle mixed movie/TV results
        let response: PaginatedResponse<MovieResult> = try await performRequest(
            path: "/discover/trending",
            queryItems: queryItems
        )

        // Transform to MediaResult
        let mediaResults = response.results.map { movie -> MediaResult in
            // Check if it's actually a TV show based on mediaType field
            if movie.mediaType == "tv" {
                // This needs special handling - for now return as movie
                // In production, you'd decode as TVResult
                return .movie(movie)
            }
            return .movie(movie)
        }

        return PaginatedResponse(
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            results: mediaResults
        )
    }

    /// Discover movies
    /// Source: seerr-api.yml /discover/movies endpoint
    /// Extended to support all slider types with custom filters
    /// - Parameters:
    ///   - page: Page number (default: 1)
    ///   - sortBy: Sort method (default: "popularity.desc")
    ///   - genre: Genre ID filter (optional)
    ///   - keywords: Keyword IDs filter (comma-separated, optional)
    ///   - excludeKeywords: Exclude keyword IDs (comma-separated, optional)
    ///   - studio: Studio ID filter (optional)
    ///   - primaryReleaseDateGte: Release date >= (YYYY-MM-DD, optional)
    ///   - primaryReleaseDateLte: Release date <= (YYYY-MM-DD, optional)
    ///   - language: Language filter (optional)
    ///   - watchRegion: Streaming region filter (optional)
    ///   - watchProviders: Provider IDs filter (pipe-separated, optional)
    /// - Returns: Paginated response of movie results
    func discoverMovies(
        page: Int = 1,
        sortBy: String = "popularity.desc",
        genre: String? = nil,
        keywords: String? = nil,
        excludeKeywords: String? = nil,
        studio: String? = nil,
        primaryReleaseDateGte: String? = nil,
        primaryReleaseDateLte: String? = nil,
        language: String? = nil,
        watchRegion: String? = nil,
        watchProviders: String? = nil,
        withRuntimeGte: Int? = nil,
        withRuntimeLte: Int? = nil,
        voteAverageGte: Double? = nil,
        voteAverageLte: Double? = nil,
        voteCountGte: Int? = nil,
        voteCountLte: Int? = nil,
        certification: String? = nil,
        certificationGte: String? = nil,
        certificationLte: String? = nil,
        certificationCountry: String? = nil
    ) async throws -> PaginatedResponse<MovieResult> {
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "sortBy", value: sortBy)
        ]

        // Add optional parameters
        if let genre = genre {
            queryItems.append(URLQueryItem(name: "genre", value: genre))
        }
        if let keywords = keywords {
            queryItems.append(URLQueryItem(name: "keywords", value: keywords))
        }
        if let excludeKeywords = excludeKeywords {
            queryItems.append(URLQueryItem(name: "excludeKeywords", value: excludeKeywords))
        }
        if let studio = studio {
            queryItems.append(URLQueryItem(name: "studio", value: studio))
        }
        if let primaryReleaseDateGte = primaryReleaseDateGte {
            queryItems.append(URLQueryItem(name: "primaryReleaseDateGte", value: primaryReleaseDateGte))
        }
        if let primaryReleaseDateLte = primaryReleaseDateLte {
            queryItems.append(URLQueryItem(name: "primaryReleaseDateLte", value: primaryReleaseDateLte))
        }
        if let language = language {
            queryItems.append(URLQueryItem(name: "language", value: language))
        }
        if let watchRegion = watchRegion {
            queryItems.append(URLQueryItem(name: "watchRegion", value: watchRegion))
        }
        if let watchProviders = watchProviders {
            queryItems.append(URLQueryItem(name: "watchProviders", value: watchProviders))
        }
        if let withRuntimeGte = withRuntimeGte {
            queryItems.append(URLQueryItem(name: "withRuntimeGte", value: String(withRuntimeGte)))
        }
        if let withRuntimeLte = withRuntimeLte {
            queryItems.append(URLQueryItem(name: "withRuntimeLte", value: String(withRuntimeLte)))
        }
        if let voteAverageGte = voteAverageGte {
            queryItems.append(URLQueryItem(name: "voteAverageGte", value: String(voteAverageGte)))
        }
        if let voteAverageLte = voteAverageLte {
            queryItems.append(URLQueryItem(name: "voteAverageLte", value: String(voteAverageLte)))
        }
        if let voteCountGte = voteCountGte {
            queryItems.append(URLQueryItem(name: "voteCountGte", value: String(voteCountGte)))
        }
        if let voteCountLte = voteCountLte {
            queryItems.append(URLQueryItem(name: "voteCountLte", value: String(voteCountLte)))
        }
        if let certification = certification {
            queryItems.append(URLQueryItem(name: "certification", value: certification))
        }
        if let certificationGte = certificationGte {
            queryItems.append(URLQueryItem(name: "certificationGte", value: certificationGte))
        }
        if let certificationLte = certificationLte {
            queryItems.append(URLQueryItem(name: "certificationLte", value: certificationLte))
        }
        if let certificationCountry = certificationCountry {
            queryItems.append(URLQueryItem(name: "certificationCountry", value: certificationCountry))
        }

        return try await performRequest(
            path: "/discover/movies",
            queryItems: queryItems
        )
    }

    /// Discover TV shows
    /// Source: seerr-api.yml /discover/tv endpoint
    /// Extended to support all slider types with custom filters
    /// - Parameters:
    ///   - page: Page number (default: 1)
    ///   - sortBy: Sort method (default: "popularity.desc")
    ///   - genre: Genre ID filter (optional)
    ///   - keywords: Keyword IDs filter (comma-separated, optional)
    ///   - excludeKeywords: Exclude keyword IDs (comma-separated, optional)
    ///   - network: Network ID filter (optional)
    ///   - firstAirDateGte: First air date >= (YYYY-MM-DD, optional)
    ///   - firstAirDateLte: First air date <= (YYYY-MM-DD, optional)
    ///   - language: Language filter (optional)
    ///   - watchRegion: Streaming region filter (optional)
    ///   - watchProviders: Provider IDs filter (pipe-separated, optional)
    /// - Returns: Paginated response of TV show results
    func discoverTV(
        page: Int = 1,
        sortBy: String = "popularity.desc",
        genre: String? = nil,
        keywords: String? = nil,
        excludeKeywords: String? = nil,
        network: String? = nil,
        firstAirDateGte: String? = nil,
        firstAirDateLte: String? = nil,
        language: String? = nil,
        watchRegion: String? = nil,
        watchProviders: String? = nil,
        withRuntimeGte: Int? = nil,
        withRuntimeLte: Int? = nil,
        voteAverageGte: Double? = nil,
        voteAverageLte: Double? = nil,
        voteCountGte: Int? = nil,
        voteCountLte: Int? = nil,
        certification: String? = nil,
        certificationGte: String? = nil,
        certificationLte: String? = nil,
        certificationCountry: String? = nil,
        status: String? = nil
    ) async throws -> PaginatedResponse<TVResult> {
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "sortBy", value: sortBy)
        ]

        // Add optional parameters
        if let genre = genre {
            queryItems.append(URLQueryItem(name: "genre", value: genre))
        }
        if let keywords = keywords {
            queryItems.append(URLQueryItem(name: "keywords", value: keywords))
        }
        if let excludeKeywords = excludeKeywords {
            queryItems.append(URLQueryItem(name: "excludeKeywords", value: excludeKeywords))
        }
        if let network = network {
            queryItems.append(URLQueryItem(name: "network", value: network))
        }
        if let firstAirDateGte = firstAirDateGte {
            queryItems.append(URLQueryItem(name: "firstAirDateGte", value: firstAirDateGte))
        }
        if let firstAirDateLte = firstAirDateLte {
            queryItems.append(URLQueryItem(name: "firstAirDateLte", value: firstAirDateLte))
        }
        if let language = language {
            queryItems.append(URLQueryItem(name: "language", value: language))
        }
        if let watchRegion = watchRegion {
            queryItems.append(URLQueryItem(name: "watchRegion", value: watchRegion))
        }
        if let watchProviders = watchProviders {
            queryItems.append(URLQueryItem(name: "watchProviders", value: watchProviders))
        }
        if let withRuntimeGte = withRuntimeGte {
            queryItems.append(URLQueryItem(name: "withRuntimeGte", value: String(withRuntimeGte)))
        }
        if let withRuntimeLte = withRuntimeLte {
            queryItems.append(URLQueryItem(name: "withRuntimeLte", value: String(withRuntimeLte)))
        }
        if let voteAverageGte = voteAverageGte {
            queryItems.append(URLQueryItem(name: "voteAverageGte", value: String(voteAverageGte)))
        }
        if let voteAverageLte = voteAverageLte {
            queryItems.append(URLQueryItem(name: "voteAverageLte", value: String(voteAverageLte)))
        }
        if let voteCountGte = voteCountGte {
            queryItems.append(URLQueryItem(name: "voteCountGte", value: String(voteCountGte)))
        }
        if let voteCountLte = voteCountLte {
            queryItems.append(URLQueryItem(name: "voteCountLte", value: String(voteCountLte)))
        }
        if let certification = certification {
            queryItems.append(URLQueryItem(name: "certification", value: certification))
        }
        if let certificationGte = certificationGte {
            queryItems.append(URLQueryItem(name: "certificationGte", value: certificationGte))
        }
        if let certificationLte = certificationLte {
            queryItems.append(URLQueryItem(name: "certificationLte", value: certificationLte))
        }
        if let certificationCountry = certificationCountry {
            queryItems.append(URLQueryItem(name: "certificationCountry", value: certificationCountry))
        }
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }

        return try await performRequest(
            path: "/discover/tv",
            queryItems: queryItems
        )
    }

    /// Get popular movies
    /// Source: seerr-api.yml /discover/movies with popularity.desc sort
    /// - Parameter page: Page number (default: 1)
    /// - Returns: Paginated response of popular movies
    func getPopularMovies(page: Int = 1) async throws -> PaginatedResponse<MediaResult> {
        let response: PaginatedResponse<MovieResult> = try await discoverMovies(
            page: page,
            sortBy: "popularity.desc"
        )

        let mediaResults = response.results.map { MediaResult.movie($0) }

        return PaginatedResponse(
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            results: mediaResults
        )
    }

    /// Get popular TV shows
    /// Source: seerr-api.yml /discover/tv with popularity.desc sort
    /// - Parameter page: Page number (default: 1)
    /// - Returns: Paginated response of popular TV shows
    func getPopularTV(page: Int = 1) async throws -> PaginatedResponse<MediaResult> {
        let response: PaginatedResponse<TVResult> = try await discoverTV(
            page: page,
            sortBy: "popularity.desc"
        )

        let mediaResults = response.results.map { MediaResult.tv($0) }

        return PaginatedResponse(
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            results: mediaResults
        )
    }

    /// Get upcoming movies
    /// Source: seerr-api.yml /discover/movies with upcoming filter
    /// Aligned with webapp behavior: sorts by popularity, no upper date limit
    /// - Parameter page: Page number (default: 1)
    /// - Returns: Paginated response of upcoming movies
    func getUpcomingMovies(page: Int = 1) async throws -> PaginatedResponse<MediaResult> {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "primaryReleaseDateGte", value: getCurrentDate())
        ]

        let response: PaginatedResponse<MovieResult> = try await performRequest(
            path: "/discover/movies",
            queryItems: queryItems
        )

        let mediaResults = response.results.map { MediaResult.movie($0) }

        return PaginatedResponse(
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            results: mediaResults
        )
    }

    /// Get upcoming TV shows
    /// Source: seerr-api.yml /discover/tv with upcoming filter
    /// Aligned with webapp behavior: sorts by popularity, no upper date limit
    /// - Parameter page: Page number (default: 1)
    /// - Returns: Paginated response of upcoming TV shows
    func getUpcomingTV(page: Int = 1) async throws -> PaginatedResponse<MediaResult> {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "firstAirDateGte", value: getCurrentDate())
        ]

        let response: PaginatedResponse<TVResult> = try await performRequest(
            path: "/discover/tv",
            queryItems: queryItems
        )

        let mediaResults = response.results.map { MediaResult.tv($0) }

        return PaginatedResponse(
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            results: mediaResults
        )
    }

    // MARK: - Helper Methods

    /// Get current date in YYYY-MM-DD format
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    /// Get date in future (for upcoming filter)
    private func getDateInFuture(months: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let futureDate = Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? Date()
        return formatter.string(from: futureDate)
    }

    // MARK: - Media Details

    /// Get movie details
    /// Source: seerr-api.yml /movie/{id} endpoint
    /// - Parameter id: TMDB movie ID
    /// - Returns: Full movie details including mediaInfo
    func getMovieDetails(id: Int) async throws -> MovieDetails {
        return try await performRequest(path: "/movie/\(id)")
    }

    /// Get TV show details
    /// Source: seerr-api.yml /tv/{id} endpoint
    /// - Parameter id: TMDB TV show ID
    /// - Returns: Full TV show details including mediaInfo
    func getTVDetails(id: Int) async throws -> TVDetails {
        return try await performRequest(path: "/tv/\(id)")
    }

    // MARK: - Requests

    /// Create a new media request
    /// Source: seerr-api.yml /request POST endpoint & TVOS_ARCH_SPEC.md Section 3.2
    /// - Parameter requestBody: Media request details
    /// - Returns: Created media request
    func createRequest(_ requestBody: MediaRequestBody) async throws -> MediaRequest {
        let encoder = JSONEncoder()
        // NOTE: Request body uses camelCase, not snake_case
        // encoder.keyEncodingStrategy = .convertToSnakeCase  // DO NOT USE
        let jsonData = try encoder.encode(requestBody)

        return try await performRequest(
            path: "/request",
            method: "POST",
            body: jsonData
        )
    }

    /// Get all requests
    /// Source: seerr-api.yml /request GET endpoint
    /// - Parameters:
    ///   - skip: Number of items to skip
    ///   - take: Number of items to take (page size)
    ///   - filter: Filter by status ("all", "approved", "pending", "processing", "available")
    /// - Returns: Array of media requests
    func getRequests(
        skip: Int = 0,
        take: Int = 20,
        filter: String = "all"
    ) async throws -> RequestsResponse {
        let queryItems = [
            URLQueryItem(name: "skip", value: String(skip)),
            URLQueryItem(name: "take", value: String(take)),
            URLQueryItem(name: "filter", value: filter)
        ]

        return try await performRequest(
            path: "/request",
            queryItems: queryItems
        )
    }

    /// Get specific request by ID
    /// Source: seerr-api.yml /request/{requestId} endpoint
    /// - Parameter requestId: Request ID
    /// - Returns: Media request details
    func getRequest(id: Int) async throws -> MediaRequest {
        return try await performRequest(path: "/request/\(id)")
    }

    /// Delete/cancel a request
    /// Source: seerr-api.yml /request/{requestId} DELETE endpoint
    /// - Parameter requestId: Request ID to cancel
    func deleteRequest(id: Int) async throws {
        guard let url = buildURL(path: "/request/\(id)") else {
            throw SeerrError.invalidURL
        }

        let request = createRequest(url: url, method: "DELETE")

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SeerrError.invalidResponse
        }

        if httpResponse.statusCode != 204 && httpResponse.statusCode != 200 {
            throw SeerrError.httpError(statusCode: httpResponse.statusCode, message: nil)
        }
    }

    // MARK: - Search

    /// Multi-search (movies, TV, people)
    /// Source: seerr-api.yml /search endpoint
    /// - Parameters:
    ///   - query: Search query string
    ///   - page: Page number (default: 1)
    /// - Returns: Paginated response of mixed search results
    func search(query: String, page: Int = 1) async throws -> PaginatedResponse<MediaResult> {
        let queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page))
        ]

        let response: PaginatedResponse<MovieResult> = try await performRequest(
            path: "/search",
            queryItems: queryItems
        )

        let mediaResults = response.results.map { MediaResult.movie($0) }

        return PaginatedResponse(
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            results: mediaResults
        )
    }

    // MARK: - Media Lists

    /// Get media list (recently added, expiring soon, etc.)
    /// Source: seerr-api.yml /media endpoint
    /// - Parameters:
    ///   - filter: Filter type (allavailable, available, partial, processing, pending)
    ///   - sort: Sort field (mediaAdded, mediaUpdated, etc.)
    ///   - take: Number of items to return (default: 20)
    ///   - skip: Number of items to skip (default: 0)
    /// - Returns: Media list response
    func getMediaList(filter: String, sort: String?, take: Int = 20, skip: Int = 0) async throws -> MediaListResponse {
        var queryItems = [
            URLQueryItem(name: "filter", value: filter),
            URLQueryItem(name: "take", value: String(take)),
            URLQueryItem(name: "skip", value: String(skip))
        ]

        if let sort = sort {
            queryItems.append(URLQueryItem(name: "sort", value: sort))
        }

        return try await performRequest(path: "/media", queryItems: queryItems)
    }

    /// Get request list (recent requests, deletion requests)
    /// Source: seerr-api.yml /request endpoint
    /// - Parameters:
    ///   - filter: Filter type (all, approved, available, pending, processing, unavailable)
    ///   - sort: Sort field (added, modified)
    ///   - take: Number of items to return (default: 20)
    ///   - skip: Number of items to skip (default: 0)
    ///   - requestedBy: Filter by user ID (optional)
    /// - Returns: Request list response
    func getRequestList(filter: String, sort: String, take: Int = 20, skip: Int = 0, requestedBy: Int? = nil) async throws -> RequestsResponse {
        var queryItems = [
            URLQueryItem(name: "filter", value: filter),
            URLQueryItem(name: "sort", value: sort),
            URLQueryItem(name: "take", value: String(take)),
            URLQueryItem(name: "skip", value: String(skip))
        ]

        if let requestedBy = requestedBy {
            queryItems.append(URLQueryItem(name: "requestedBy", value: String(requestedBy)))
        }

        return try await performRequest(path: "/request", queryItems: queryItems)
    }

    /// Get upcoming calendar items
    /// Source: seerr-api.yml /calendar/upcoming endpoint
    /// - Parameters:
    ///   - startDate: Start date in YYYY-MM-DD format
    ///   - endDate: End date in YYYY-MM-DD format
    /// - Returns: Array of calendar items
    func getUpcomingCalendar(startDate: String, endDate: String, type: String = "all", watchlistOnly: Bool = false) async throws -> [CalendarItem] {
        let queryItems = [
            URLQueryItem(name: "start", value: startDate),
            URLQueryItem(name: "end", value: endDate),
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "watchlistOnly", value: String(watchlistOnly))
        ]

        let response: CalendarResponse = try await performRequest(path: "/calendar/upcoming", queryItems: queryItems)
        // Flatten all items from all days
        return response.results.flatMap { $0.items }
    }

    /// Get watchlist from Seerr database
    /// Source: seerr-api.yml /discover/watchlist endpoint
    /// - Parameter page: Page number (default: 1)
    /// - Returns: Array of watchlist items
    func getWatchlist(page: Int = 1) async throws -> [WatchlistItem] {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page))
        ]

        let response: PaginatedResponse<WatchlistItem> = try await performRequest(path: "/discover/watchlist", queryItems: queryItems)
        return response.results
    }

    // MARK: - Available Media

    /// Get available media (movies or TV shows already in library)
    /// Source: seerr-api.yml /available/movies endpoint
    /// Returns media with status 4 (partially available) or 5 (fully available)
    /// - Parameters:
    ///   - type: Media type ("movie" or "tv")
    ///   - page: Page number (default: 1)
    ///   - sortBy: Sort method (mediaAddedAt, popularity, releaseDate, rating, title)
    /// - Returns: Paginated response with enriched TMDB data
    func getAvailableMedia(
        type: String = "movie",
        page: Int = 1,
        sortBy: String = "mediaAddedAt"
    ) async throws -> PaginatedResponse<MediaResult> {
        let queryItems = [
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "sortBy", value: sortBy)
        ]

        // The response format matches MovieResult structure (enriched with TMDB data)
        // Use camelCase decoder because /available/movies returns camelCase keys
        let response: PaginatedResponse<MovieResult> = try await performRequestCamelCase(
            path: "/available/movies",
            queryItems: queryItems
        )

        // Convert to MediaResult based on type
        let mediaResults = response.results.map { movie -> MediaResult in
            if type == "tv" {
                // For TV shows, we should ideally decode as TVResult
                // But the server returns the same enriched format
                return .movie(movie)
            }
            return .movie(movie)
        }

        return PaginatedResponse(
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            results: mediaResults
        )
    }

    // MARK: - Genre Sliders

    /// Get movie genres with backdrop images
    /// Source: seerr-api.yml /discover/genreslider/movie endpoint
    /// Returns genres with backdrop images for visual genre cards
    /// - Returns: Array of movie genres with backdrops
    func getMovieGenres() async throws -> [Genre] {
        return try await performRequest(path: "/discover/genreslider/movie")
    }

    /// Get TV genres with backdrop images
    /// Source: seerr-api.yml /discover/genreslider/tv endpoint
    /// Returns genres with backdrop images for visual genre cards
    /// - Returns: Array of TV genres with backdrops
    func getTVGenres() async throws -> [Genre] {
        return try await performRequest(path: "/discover/genreslider/tv")
    }

    /// Get movies by genre
    /// Source: seerr-api.yml /discover/genreslider/movie/{genreId} endpoint
    /// - Parameters:
    ///   - genreId: Genre ID
    ///   - page: Page number (default: 1)
    /// - Returns: Paginated response of movies
    func getMoviesByGenre(genreId: Int, page: Int = 1) async throws -> PaginatedResponse<MediaResult> {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page))
        ]

        let response: PaginatedResponse<MovieResult> = try await performRequest(
            path: "/discover/genreslider/movie/\(genreId)",
            queryItems: queryItems
        )

        let mediaResults = response.results.map { MediaResult.movie($0) }
        return PaginatedResponse(
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            results: mediaResults
        )
    }

    /// Get TV shows by genre
    /// Source: seerr-api.yml /discover/genreslider/tv/{genreId} endpoint
    /// - Parameters:
    ///   - genreId: Genre ID
    ///   - page: Page number (default: 1)
    /// - Returns: Paginated response of TV shows
    func getTVByGenre(genreId: Int, page: Int = 1) async throws -> PaginatedResponse<MediaResult> {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page))
        ]

        let response: PaginatedResponse<TVResult> = try await performRequest(
            path: "/discover/genreslider/tv/\(genreId)",
            queryItems: queryItems
        )

        let mediaResults = response.results.map { MediaResult.tv($0) }
        return PaginatedResponse(
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            results: mediaResults
        )
    }

    // MARK: - Studio & Network

    /// Get movies by studio
    /// Source: seerr-api.yml /discover/movies/studio/{studioId} endpoint
    /// - Parameters:
    ///   - studioId: Studio ID
    ///   - page: Page number (default: 1)
    /// - Returns: Paginated response of movies
    func getMoviesByStudio(studioId: Int, page: Int = 1) async throws -> PaginatedResponse<MediaResult> {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page))
        ]

        let response: PaginatedResponse<MovieResult> = try await performRequest(
            path: "/discover/movies/studio/\(studioId)",
            queryItems: queryItems
        )

        let mediaResults = response.results.map { MediaResult.movie($0) }
        return PaginatedResponse(
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            results: mediaResults
        )
    }

    /// Get TV shows by network
    /// Source: seerr-api.yml /discover/tv/network/{networkId} endpoint
    /// - Parameters:
    ///   - networkId: Network ID
    ///   - page: Page number (default: 1)
    /// - Returns: Paginated response of TV shows
    func getTVByNetwork(networkId: Int, page: Int = 1) async throws -> PaginatedResponse<MediaResult> {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page))
        ]

        let response: PaginatedResponse<TVResult> = try await performRequest(
            path: "/discover/tv/network/\(networkId)",
            queryItems: queryItems
        )

        let mediaResults = response.results.map { MediaResult.tv($0) }
        return PaginatedResponse(
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            results: mediaResults
        )
    }

    // MARK: - User

    /// Get current user info
    /// Source: seerr-api.yml /auth/me endpoint
    /// - Returns: Current authenticated user
    func getCurrentUser() async throws -> User {
        return try await performRequest(path: "/auth/me")
    }

    /// Get Seerr server status (public endpoint, no auth required)
    /// Source: seerr-api.yml /status endpoint
    /// - Returns: Server status information
    func getStatus() async throws -> ServerStatus {
        return try await performRequest(path: "/status")
    }

    // MARK: - Deletion Requests

    /// Get deletion requests list (paginated)
    /// Source: seerr-api.yml /deletion GET endpoint
    /// - Parameters:
    ///   - take: Number of items to return (default: 20)
    ///   - skip: Number of items to skip (default: 0)
    ///   - status: Filter by status (optional)
    /// - Returns: Deletion requests response with pagination
    func getDeletionRequests(
        take: Int = 20,
        skip: Int = 0,
        status: DeletionRequestStatus? = nil
    ) async throws -> DeletionRequestsResponse {
        var queryItems = [
            URLQueryItem(name: "take", value: String(take)),
            URLQueryItem(name: "skip", value: String(skip))
        ]

        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status.rawValue))
        }

        return try await performRequest(
            path: "/deletion",
            queryItems: queryItems
        )
    }

    /// Get single deletion request by ID
    /// Source: seerr-api.yml /deletion/:id GET endpoint
    /// - Parameter id: Deletion request ID
    /// - Returns: Deletion request details
    func getDeletionRequest(id: Int) async throws -> DeletionRequest {
        return try await performRequest(path: "/deletion/\(id)")
    }

    /// Check if active deletion request exists for media
    /// Source: seerr-api.yml /deletion/check/:mediaId GET endpoint
    /// - Parameters:
    ///   - mediaId: Media ID in Seerr database
    ///   - mediaType: "movie" or "tv"
    /// - Returns: Active deletion request if exists
    func checkDeletionRequest(mediaId: Int, mediaType: String) async throws -> DeletionRequest? {
        let queryItems = [
            URLQueryItem(name: "mediaType", value: mediaType)
        ]

        let response: CheckDeletionResponse = try await performRequest(
            path: "/deletion/check/\(mediaId)",
            queryItems: queryItems
        )

        return response.deletionRequest
    }

    /// Create a new deletion request
    /// Source: seerr-api.yml /deletion POST endpoint
    /// - Parameter body: Deletion request creation details
    /// - Returns: Created deletion request
    func createDeletionRequest(_ body: CreateDeletionRequestBody) async throws -> DeletionRequest {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let jsonData = try encoder.encode(body)

        return try await performRequest(
            path: "/deletion",
            method: "POST",
            body: jsonData
        )
    }

    /// Cast or change vote on deletion request
    /// Source: seerr-api.yml /deletion/:id/vote POST endpoint
    /// - Parameters:
    ///   - deletionRequestId: Deletion request ID
    ///   - vote: true = vote for deletion (remove), false = vote against (keep)
    /// - Returns: Updated deletion vote
    func voteDeletionRequest(deletionRequestId: Int, vote: Bool) async throws -> DeletionVote {
        let body = DeletionVoteBody(vote: vote)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let jsonData = try encoder.encode(body)

        return try await performRequest(
            path: "/deletion/\(deletionRequestId)/vote",
            method: "POST",
            body: jsonData
        )
    }

    /// Remove user's vote on deletion request
    /// Source: seerr-api.yml /deletion/:id/vote DELETE endpoint
    /// - Parameter deletionRequestId: Deletion request ID
    func removeVoteDeletionRequest(deletionRequestId: Int) async throws {
        guard let url = buildURL(path: "/deletion/\(deletionRequestId)/vote") else {
            throw SeerrError.invalidURL
        }

        let request = createRequest(url: url, method: "DELETE")

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SeerrError.invalidResponse
        }

        if httpResponse.statusCode != 204 && httpResponse.statusCode != 200 {
            throw SeerrError.httpError(statusCode: httpResponse.statusCode, message: nil)
        }
    }

    /// Get current user's vote on deletion request
    /// Source: seerr-api.yml /deletion/:id/vote/me GET endpoint
    /// - Parameter deletionRequestId: Deletion request ID
    /// - Returns: User's vote if exists, nil otherwise
    func getMyDeletionVote(deletionRequestId: Int) async throws -> DeletionVote? {
        do {
            return try await performRequest(path: "/deletion/\(deletionRequestId)/vote/me")
        } catch SeerrError.notFound {
            // No vote found for this user
            return nil
        } catch {
            throw error
        }
    }

    /// Execute approved deletion request (admin only)
    /// Source: seerr-api.yml /deletion/:id/execute POST endpoint
    /// - Parameter deletionRequestId: Deletion request ID
    /// - Returns: Updated deletion request
    func executeDeletionRequest(deletionRequestId: Int) async throws -> DeletionRequest {
        return try await performRequest(
            path: "/deletion/\(deletionRequestId)/execute",
            method: "POST"
        )
    }

    /// Cancel deletion request (requester or admin)
    /// Source: seerr-api.yml /deletion/:id/cancel POST endpoint
    /// - Parameter deletionRequestId: Deletion request ID
    /// - Returns: Updated deletion request
    func cancelDeletionRequest(deletionRequestId: Int) async throws -> DeletionRequest {
        return try await performRequest(
            path: "/deletion/\(deletionRequestId)/cancel",
            method: "POST"
        )
    }

    // MARK: - Authentication

    /// Sign in using local account (email/password)
    /// Source: seerr-api.yml /auth/local endpoint
    /// - Parameters:
    ///   - email: User email
    ///   - password: User password
    /// - Returns: Authenticated user object
    func loginLocal(email: String, password: String) async throws -> User {
        // Build request body
        let requestBody = LocalLoginRequest(email: email, password: password)
        let bodyData = try JSONEncoder().encode(requestBody)

        // Perform login request
        let user: User = try await performRequest(
            path: "/auth/local",
            method: "POST",
            body: bodyData
        )

        return user
    }

    /// Sign in using Jellyfin account (username/password)
    /// Source: seerr-api.yml /auth/jellyfin endpoint
    /// - Parameters:
    ///   - username: Jellyfin username
    ///   - password: User password
    /// - Returns: Authenticated user object
    func loginJellyfin(username: String, password: String) async throws -> User {
        // Build request body
        let requestBody = JellyfinLoginRequest(username: username, password: password)
        let bodyData = try JSONEncoder().encode(requestBody)

        // Perform login request
        let user: User = try await performRequest(
            path: "/auth/jellyfin",
            method: "POST",
            body: bodyData
        )

        return user
    }

    /// Sign out and clear session
    /// Source: seerr-api.yml /auth/logout endpoint
    func logout() async throws {
        struct LogoutResponse: Codable {
            let status: String
        }

        let _: LogoutResponse = try await performRequest(
            path: "/auth/logout",
            method: "POST"
        )
    }
}

// MARK: - Supporting Types

/// Local login request body
private struct LocalLoginRequest: Codable {
    let email: String
    let password: String
}

/// Jellyfin login request body
private struct JellyfinLoginRequest: Codable {
    let username: String
    let password: String
}

/// Server status response
/// Source: seerr-api.yml /status endpoint
struct ServerStatus: Codable {
    let version: String
    let commitTag: String?
    let updateAvailable: Bool?
    let commitsBehind: Int?
    let restartRequired: Bool?
}

/// Requests response container
struct RequestsResponse: Codable {
    let pageInfo: PageInfo
    let results: [MediaRequest]
}

/// Page info for requests
struct PageInfo: Codable {
    let pages: Int
    let pageSize: Int
    let results: Int
    let page: Int
}
