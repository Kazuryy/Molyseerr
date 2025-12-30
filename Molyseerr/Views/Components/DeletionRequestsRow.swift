//
//  DeletionRequestsRow.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import SwiftUI

/// Horizontal row of deletion requests (slider)
/// Reference: Seerr DeletionRequestSlider component
/// Used on home page to show active voting requests
struct DeletionRequestsRow: View {

    // MARK: - Properties

    @StateObject private var viewModel = DeletionRequestsViewModel()
    @State private var isLoaded: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("Voting Now - Leaving Soon")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                // "View All" button (only show if there are requests)
                if !viewModel.votingRequests.isEmpty {
                    NavigationLink(destination: DeletionRequestsListView()) {
                        HStack(spacing: 8) {
                            Text("View All")
                            Image(systemName: "chevron.right")
                        }
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 90)

            // Content area
            if viewModel.isVotingLoading {
                loadingView
            } else if viewModel.votingRequests.isEmpty {
                emptyView
            } else {
                scrollView
            }
        }
        .task {
            guard !isLoaded else { return }
            await viewModel.loadVotingRequests()
            isLoaded = true
        }
    }

    // MARK: - Subviews

    /// Scrollable row of deletion cards
    private var scrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(viewModel.votingRequests) { request in
                    DeletionSliderCard(
                        deletionRequest: request,
                        userVote: viewModel.userVotes[request.id],
                        onVoteKeep: {
                            await viewModel.voteAgainstDeletion(requestId: request.id)
                        },
                        onVoteRemove: {
                            await viewModel.voteForDeletion(requestId: request.id)
                        }
                    )
                }
            }
            .padding(.horizontal, 90)
            .padding(.vertical, 20)
        }
    }

    /// Loading placeholder
    private var loadingView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 24) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 640, height: 360)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 90)
            .padding(.vertical, 20)
        }
    }

    /// Empty state when no deletion requests
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("No Deletion Requests")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("There are no items up for deletion at the moment.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
