//
//  SeerrService.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import Foundation

/// Seerr API Service - Singleton
/// Uses async/await with URLSession as per TECH_RULES.md Section 1
/// Source: seerr-api.yml for all endpoints
@MainActor
final class SeerrService: ObservableObject {

    // MARK: - Singleton
    static let shared = SeerrService()

    // MARK: - Configuration
    /// TEMPORARY: API Key for authentication (MVP approach from TECH_RULES.md)
    /// TODO: Replace with proper authentication flow
    private var apiKey: String = "YOUR_API_KEY_HERE"

    /// Base URL for Seerr API
    /// Source: seerr-api.yml servers section (default: http://localhost:5055)
    private var baseURL: String = "http://localhost:5055"

    /// URL Session for network requests
    private let session: URLSession

    // MARK: - Initialization
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
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

    // MARK: - Discovery & Trending

    /// Get trending media (movies and TV shows)
    /// Source: seerr-api.yml /discover/trending endpoint
    /// - Parameters:
    ///   - page: Page number (default: 1)
    ///   - timeWindow: Time window ("day" or "week", default: "day")
    /// - Returns: Paginated response of mixed media results
    func getTrending(page: Int = 1, timeWindow: String = "day") async throws -> PaginatedResponse<MediaResult> {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "timeWindow", value: timeWindow)
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
    /// - Parameters:
    ///   - page: Page number (default: 1)
    ///   - sortBy: Sort method (default: "popularity.desc")
    ///   - genre: Genre ID filter (optional)
    /// - Returns: Paginated response of movie results
    func discoverMovies(
        page: Int = 1,
        sortBy: String = "popularity.desc",
        genre: Int? = nil
    ) async throws -> PaginatedResponse<MovieResult> {
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "sortBy", value: sortBy)
        ]

        if let genre = genre {
            queryItems.append(URLQueryItem(name: "genre", value: String(genre)))
        }

        return try await performRequest(
            path: "/discover/movies",
            queryItems: queryItems
        )
    }

    /// Discover TV shows
    /// Source: seerr-api.yml /discover/tv endpoint
    /// - Parameters:
    ///   - page: Page number (default: 1)
    ///   - sortBy: Sort method (default: "popularity.desc")
    ///   - genre: Genre ID filter (optional)
    /// - Returns: Paginated response of TV show results
    func discoverTV(
        page: Int = 1,
        sortBy: String = "popularity.desc",
        genre: Int? = nil
    ) async throws -> PaginatedResponse<TVResult> {
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "sortBy", value: sortBy)
        ]

        if let genre = genre {
            queryItems.append(URLQueryItem(name: "genre", value: String(genre)))
        }

        return try await performRequest(
            path: "/discover/tv",
            queryItems: queryItems
        )
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
        encoder.keyEncodingStrategy = .convertToSnakeCase
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

        var request = createRequest(url: url, method: "DELETE")

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

    // MARK: - User

    /// Get current user info
    /// Source: seerr-api.yml /user/me endpoint
    /// - Returns: Current authenticated user
    func getCurrentUser() async throws -> User {
        return try await performRequest(path: "/user/me")
    }
}

// MARK: - Supporting Types

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
