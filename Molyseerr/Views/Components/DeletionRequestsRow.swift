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
        Group {
            // Only show if there are voting requests or still loading
            if viewModel.isVotingLoading || !viewModel.votingRequests.isEmpty {
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
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 90)

                    // Horizontal scroll view
                    if viewModel.isVotingLoading {
                        loadingView
                    } else {
                        scrollView
                    }
                }
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
            LazyHStack(spacing: 24) {
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
}
