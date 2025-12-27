//
//  DeletionRequestsListView.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import SwiftUI

/// Full deletion requests list view with filtering
/// Reference: Seerr DeletionRequestList component
/// Displays all deletion requests with status filtering
struct DeletionRequestsListView: View {

    // MARK: - Properties

    @StateObject private var viewModel = DeletionRequestsViewModel()
    @State private var isLoaded: Bool = false

    // Filter options
    private let filterOptions: [(String, DeletionRequestStatus?)] = [
        ("All", nil),
        ("Voting", .voting),
        ("Approved", .approved),
        ("Rejected", .rejected),
        ("Completed", .completed),
        ("Cancelled", .cancelled)
    ]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                header

                // Filter buttons
                filterButtons

                // Content
                if viewModel.isLoading && viewModel.deletionRequests.isEmpty {
                    loadingView
                } else if viewModel.deletionRequests.isEmpty {
                    emptyView
                } else {
                    contentList
                }

                // Error message
                if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                }
            }
            .padding(.horizontal, 90)
            .padding(.vertical, 40)
        }
        .background(Color.black)
        .task {
            guard !isLoaded else { return }
            await viewModel.loadDeletionRequests(reset: true)
            isLoaded = true
        }
    }

    // MARK: - Subviews

    /// Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deletion Requests")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Community voting for content removal")
                .font(.title3)
                .foregroundColor(.white.opacity(0.6))
        }
    }

    /// Filter buttons
    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(filterOptions, id: \.0) { option in
                    Button(action: {
                        Task {
                            await viewModel.changeFilter(to: option.1)
                        }
                    }) {
                        Text(option.0)
                            .font(.body)
                            .fontWeight(viewModel.currentFilter == option.1 ? .bold : .regular)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(viewModel.currentFilter == option.1 ? Color.white : Color.white.opacity(0.2))
                            .foregroundColor(viewModel.currentFilter == option.1 ? Color.black : Color.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Content list
    private var contentList: some View {
        VStack(spacing: 24) {
            ForEach(viewModel.deletionRequests) { request in
                DeletionRequestCard(
                    deletionRequest: request,
                    userVote: viewModel.userVotes[request.id],
                    onVoteKeep: {
                        await viewModel.voteAgainstDeletion(requestId: request.id)
                    },
                    onVoteRemove: {
                        await viewModel.voteForDeletion(requestId: request.id)
                    },
                    onRemoveVote: {
                        await viewModel.removeVote(requestId: request.id)
                    },
                    onExecute: {
                        await viewModel.executeDeletion(requestId: request.id)
                    },
                    onCancel: {
                        await viewModel.cancelDeletion(requestId: request.id)
                    }
                )
            }

            // Load more button
            if viewModel.currentPage < viewModel.totalPages {
                Button(action: {
                    Task {
                        await viewModel.loadNextPage()
                    }
                }) {
                    HStack(spacing: 8) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        }
                        Text(viewModel.isLoading ? "Loading..." : "Load More")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Loading view
    private var loadingView: some View {
        VStack(spacing: 24) {
            ForEach(0..<3, id: \.self) { _ in
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 300)
                    .cornerRadius(12)
            }
        }
    }

    /// Empty view
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.3))

            Text("No deletion requests found")
                .font(.title2)
                .foregroundColor(.white.opacity(0.6))

            if let filter = viewModel.currentFilter {
                Text("Try changing the filter from \"\(filter.displayName)\"")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
    }

    /// Error view
    private func errorView(_ message: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)

            Text(message)
                .font(.body)
                .foregroundColor(.white)

            Spacer()

            Button("Retry") {
                Task {
                    await viewModel.refresh()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
        }
        .padding(20)
        .background(Color.red.opacity(0.2))
        .cornerRadius(12)
    }
}
