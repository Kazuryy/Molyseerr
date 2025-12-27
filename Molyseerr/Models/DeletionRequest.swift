//
//  DeletionRequest.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import Foundation

/// Deletion request status enum
/// Source: Seerr /api/v1/deletion endpoint
enum DeletionRequestStatus: String, Codable {
    case pending = "pending"
    case voting = "voting"
    case approved = "approved"
    case rejected = "rejected"
    case completed = "completed"
    case cancelled = "cancelled"

    /// Display name for UI
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .voting: return "Voting"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    /// Color scheme for status badge
    var badgeColor: String {
        switch self {
        case .pending: return "gray"
        case .voting: return "blue"
        case .approved: return "green"
        case .rejected: return "red"
        case .completed: return "purple"
        case .cancelled: return "orange"
        }
    }
}

/// Deletion request model
/// Source: Seerr /api/v1/deletion endpoint
struct DeletionRequest: Codable, Identifiable {
    let id: Int
    let mediaId: Int
    let mediaType: String // "movie" or "tv"
    let tmdbId: Int
    let title: String
    let posterPath: String?
    let status: DeletionRequestStatus
    let reason: String?
    let requestedBy: User
    let votingEndsAt: String?
    let votesFor: Int
    let votesAgainst: Int
    let processedAt: String?
    let processedBy: User?
    let createdAt: String
    let updatedAt: String

    // Computed properties from API
    let isVotingActive: Bool?
    let votePercentage: Double?
    let totalVotes: Int?

    /// Total votes count (computed fallback)
    var votes: Int {
        totalVotes ?? (votesFor + votesAgainst)
    }

    /// Voting progress percentage (0.0 to 1.0)
    var voteProgress: Double {
        guard votes > 0 else { return 0.0 }
        return Double(votesFor) / Double(votes)
    }

    /// Keep votes progress percentage (0.0 to 1.0)
    var keepProgress: Double {
        guard votes > 0 else { return 0.0 }
        return Double(votesAgainst) / Double(votes)
    }

    /// Formatted voting end time (relative)
    var votingEndsAtFormatted: String? {
        guard let votingEndsAt = votingEndsAt else { return nil }

        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: votingEndsAt) else { return nil }

        let now = Date()
        let interval = date.timeIntervalSince(now)

        if interval < 0 {
            return "Voting ended"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m remaining"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h remaining"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d remaining"
        }
    }

    /// Full poster URL
    var posterURL: String? {
        guard let posterPath = posterPath else { return nil }
        return TMDBImageHelper.posterURL(path: posterPath)?.absoluteString
    }

    /// Backdrop URL (use poster as fallback)
    var backdropURL: String? {
        guard let posterPath = posterPath else { return nil }
        return TMDBImageHelper.backdropURL(path: posterPath)?.absoluteString
    }
}

/// Deletion vote model
/// Source: Seerr /api/v1/deletion/:id/vote endpoint
struct DeletionVote: Codable, Identifiable {
    let id: Int
    let deletionRequestId: Int?
    let user: User
    let vote: Bool // true = for deletion, false = against deletion
    let createdAt: String

    /// Display text for vote
    var voteText: String {
        vote ? "Remove" : "Keep"
    }
}

/// Deletion request creation body
/// Source: Seerr /api/v1/deletion POST endpoint
struct CreateDeletionRequestBody: Codable {
    let mediaId: Int
    let mediaType: String // "movie" or "tv"
    let reason: String?
}

/// Deletion vote body
/// Source: Seerr /api/v1/deletion/:id/vote POST endpoint
struct DeletionVoteBody: Codable {
    let vote: Bool // true = for deletion (remove), false = against deletion (keep)
}

/// Deletion requests paginated response
/// Source: Seerr /api/v1/deletion endpoint
struct DeletionRequestsResponse: Codable {
    let pageInfo: DeletionPageInfo
    let results: [DeletionRequest]
}

/// Page info for deletion requests
struct DeletionPageInfo: Codable {
    let pages: Int
    let pageSize: Int
    let results: Int
    let page: Int
}

/// Check deletion request response
/// Source: Seerr /api/v1/deletion/check/:mediaId endpoint
struct CheckDeletionResponse: Codable {
    let deletionRequest: DeletionRequest?
}
