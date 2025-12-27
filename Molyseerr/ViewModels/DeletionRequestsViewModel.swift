//
//  DeletionRequestsViewModel.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import Foundation
import Combine

/// ViewModel for Deletion Requests feature
/// Manages deletion requests list, voting, and filtering
/// Source: Seerr /api/v1/deletion endpoints
@MainActor
final class DeletionRequestsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Deletion requests list
    @Published var deletionRequests: [DeletionRequest] = []

    /// Active voting requests (for slider)
    @Published var votingRequests: [DeletionRequest] = []

    /// Loading states
    @Published var isLoading: Bool = false
    @Published var isVotingLoading: Bool = false

    /// Error message
    @Published var errorMessage: String?

    /// Current filter
    @Published var currentFilter: DeletionRequestStatus? = nil

    /// Current page
    @Published var currentPage: Int = 1

    /// Total pages
    @Published var totalPages: Int = 1

    /// Page size
    @Published var pageSize: Int = 20

    /// User's votes map (deletionRequestId -> vote)
    @Published var userVotes: [Int: Bool] = [:]

    // MARK: - Private Properties

    private let seerrService: SeerrService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(seerrService: SeerrService = .shared) {
        self.seerrService = seerrService
    }

    // MARK: - Public Methods

    /// Load deletion requests with current filter
    func loadDeletionRequests(reset: Bool = false) async {
        if reset {
            currentPage = 1
            deletionRequests = []
        }

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let skip = (currentPage - 1) * pageSize

            let response = try await seerrService.getDeletionRequests(
                take: pageSize,
                skip: skip,
                status: currentFilter
            )

            if reset {
                deletionRequests = response.results
            } else {
                deletionRequests.append(contentsOf: response.results)
            }

            totalPages = response.pageInfo.pages

            // Load user votes for each request
            await loadUserVotes()

        } catch {
            handleError(error)
        }
    }

    /// Load only voting requests (for slider)
    func loadVotingRequests() async {
        guard !isVotingLoading else { return }

        isVotingLoading = true
        defer { isVotingLoading = false }

        do {
            let response = try await seerrService.getDeletionRequests(
                take: 20,
                skip: 0,
                status: .voting
            )

            votingRequests = response.results

            // Load user votes
            for request in votingRequests {
                await loadUserVote(for: request.id)
            }

        } catch {
            print("❌ Error loading voting requests: \(error)")
        }
    }

    /// Change filter and reload
    func changeFilter(to status: DeletionRequestStatus?) async {
        currentFilter = status
        await loadDeletionRequests(reset: true)
    }

    /// Load next page
    func loadNextPage() async {
        guard currentPage < totalPages else { return }
        currentPage += 1
        await loadDeletionRequests(reset: false)
    }

    /// Refresh all data
    func refresh() async {
        currentPage = 1
        deletionRequests = []
        userVotes = [:]
        await loadDeletionRequests(reset: true)
        await loadVotingRequests()
    }

    /// Vote for deletion (remove)
    func voteForDeletion(requestId: Int) async {
        await castVote(requestId: requestId, vote: true)
    }

    /// Vote against deletion (keep)
    func voteAgainstDeletion(requestId: Int) async {
        await castVote(requestId: requestId, vote: false)
    }

    /// Remove vote
    func removeVote(requestId: Int) async {
        do {
            try await seerrService.removeVoteDeletionRequest(deletionRequestId: requestId)

            // Update local state
            userVotes[requestId] = nil

            // Refresh the specific request
            await refreshRequest(requestId: requestId)

        } catch {
            handleError(error)
        }
    }

    /// Execute deletion (admin only)
    func executeDeletion(requestId: Int) async {
        do {
            _ = try await seerrService.executeDeletionRequest(deletionRequestId: requestId)

            // Refresh data
            await refresh()

        } catch {
            handleError(error)
        }
    }

    /// Cancel deletion request
    func cancelDeletion(requestId: Int) async {
        do {
            _ = try await seerrService.cancelDeletionRequest(deletionRequestId: requestId)

            // Refresh data
            await refresh()

        } catch {
            handleError(error)
        }
    }

    // MARK: - Private Methods

    /// Cast vote (internal)
    private func castVote(requestId: Int, vote: Bool) async {
        do {
            _ = try await seerrService.voteDeletionRequest(deletionRequestId: requestId, vote: vote)

            // Update local state
            userVotes[requestId] = vote

            // Refresh the specific request
            await refreshRequest(requestId: requestId)

        } catch {
            handleError(error)
        }
    }

    /// Load user votes for all current requests
    private func loadUserVotes() async {
        await withTaskGroup(of: Void.self) { group in
            for request in deletionRequests {
                group.addTask {
                    await self.loadUserVote(for: request.id)
                }
            }
        }
    }

    /// Load user vote for specific request
    private func loadUserVote(for requestId: Int) async {
        do {
            if let vote = try await seerrService.getMyDeletionVote(deletionRequestId: requestId) {
                userVotes[requestId] = vote.vote
            }
        } catch {
            // User hasn't voted yet, ignore error
            print("No vote found for request \(requestId)")
        }
    }

    /// Refresh specific deletion request
    private func refreshRequest(requestId: Int) async {
        do {
            let updatedRequest = try await seerrService.getDeletionRequest(id: requestId)

            // Update in main list
            if let index = deletionRequests.firstIndex(where: { $0.id == requestId }) {
                deletionRequests[index] = updatedRequest
            }

            // Update in voting list
            if let index = votingRequests.firstIndex(where: { $0.id == requestId }) {
                votingRequests[index] = updatedRequest
            }

        } catch {
            print("❌ Error refreshing request: \(error)")
        }
    }

    /// Handle errors
    private func handleError(_ error: Error) {
        print("❌ DeletionRequestsViewModel error: \(error)")

        if let seerrError = error as? SeerrError {
            errorMessage = mapSeerrError(seerrError)
        } else {
            errorMessage = error.localizedDescription
        }
    }

    /// Map SeerrError to user-friendly message
    private func mapSeerrError(_ error: SeerrError) -> String {
        switch error {
        case .invalidURL:
            return "Invalid server URL configuration."
        case .unauthorized:
            return "Unauthorized. Please check your API key."
        case .forbidden:
            return "Access forbidden. You may not have permission."
        case .notFound:
            return "Deletion request not found."
        case .serverError:
            return "Server error. Please try again later."
        case .invalidResponse:
            return "Invalid response from server."
        case .decodingError:
            return "Failed to process deletion request data."
        case .networkError(let underlyingError):
            return "Network error: \(underlyingError.localizedDescription)"
        case .httpError(let statusCode, let message):
            if let message = message {
                return "Error \(statusCode): \(message)"
            }
            return "HTTP error: \(statusCode)"
        case .unknown:
            return "An unknown error occurred."
        case .notImplemented:
            return "This feature is not yet implemented."
        case .configurationError(let message):
            return message
        }
    }
}
