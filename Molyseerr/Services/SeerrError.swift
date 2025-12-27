//
//  SeerrError.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import Foundation

/// Seerr API error types
/// Proper error mapping as specified in TECH_RULES.md
enum SeerrError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case unauthorized
    case forbidden
    case notFound
    case serverError
    case unknown
    case notImplemented
    case configurationError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message ?? "Unknown error")"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized: Invalid API key or session"
        case .forbidden:
            return "Forbidden: Insufficient permissions"
        case .notFound:
            return "Resource not found"
        case .serverError:
            return "Server error"
        case .unknown:
            return "Unknown error occurred"
        case .notImplemented:
            return "Not yet implemented"
        case .configurationError(let message):
            return message
        }
    }
}
