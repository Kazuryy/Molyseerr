//
//  DeletionSliderCard.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import SwiftUI
import Kingfisher

/// Compact deletion request card for horizontal slider
/// Reference: Seerr DeletionSliderCard component
/// Optimized for tvOS Focus Engine
struct DeletionSliderCard: View {

    // MARK: - Properties

    let deletionRequest: DeletionRequest
    let userVote: Bool?
    let onVoteKeep: () async -> Void
    let onVoteRemove: () async -> Void

    @FocusState private var isFocused: Bool
    @State private var isVoting: Bool = false

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background image
            backdropImage

            // Content overlay
            VStack(alignment: .leading, spacing: 16) {
                Spacer()

                // Status badge
                statusBadge

                // Title and info
                VStack(alignment: .leading, spacing: 8) {
                    Text(deletionRequest.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    if let votingEndsAt = deletionRequest.votingEndsAtFormatted {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            Text(votingEndsAt)
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }

                    // Vote progress bar
                    voteProgressBar
                }

                // Vote buttons
                if deletionRequest.isVotingActive == true {
                    voteButtons
                }
            }
            .padding(24)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.0),
                        Color.black.opacity(0.7),
                        Color.black.opacity(0.9)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(width: 640, height: 360)
        .cornerRadius(12)
        .focusable()
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .shadow(color: isFocused ? .white.opacity(0.3) : .clear, radius: 20)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }

    // MARK: - Subviews

    /// Backdrop image with gradient
    private var backdropImage: some View {
        Group {
            if let backdropURL = deletionRequest.backdropURL {
                KFImage(URL(string: backdropURL))
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 640, height: 360)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
        }
    }

    /// Status badge
    private var statusBadge: some View {
        Text(deletionRequest.status.displayName.uppercased())
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.9))
            .cornerRadius(6)
    }

    /// Vote progress bar
    private var voteProgressBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Text("\(deletionRequest.votesAgainst) Keep")
                    .font(.caption)
                    .foregroundColor(.green)

                Spacer()

                Text("\(deletionRequest.votesFor) Remove")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background (remove votes)
                    Rectangle()
                        .fill(Color.red.opacity(0.6))

                    // Foreground (keep votes)
                    Rectangle()
                        .fill(Color.green.opacity(0.8))
                        .frame(width: geometry.size.width * CGFloat(deletionRequest.keepProgress))
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
    }

    /// Vote buttons
    private var voteButtons: some View {
        HStack(spacing: 16) {
            // Keep button
            Button(action: {
                Task {
                    isVoting = true
                    await onVoteKeep()
                    isVoting = false
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: userVote == false ? "checkmark.circle.fill" : "checkmark.circle")
                    Text("Keep")
                        .fontWeight(userVote == false ? .bold : .regular)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(userVote == false ? Color.green : Color.white.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.borderless)
            .disabled(isVoting)

            // Remove button
            Button(action: {
                Task {
                    isVoting = true
                    await onVoteRemove()
                    isVoting = false
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: userVote == true ? "xmark.circle.fill" : "xmark.circle")
                    Text("Remove")
                        .fontWeight(userVote == true ? .bold : .regular)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(userVote == true ? Color.red : Color.white.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.borderless)
            .disabled(isVoting)
        }
    }

    // MARK: - Helpers

    /// Status color based on status
    private var statusColor: Color {
        switch deletionRequest.status {
        case .pending:
            return .gray
        case .voting:
            return .blue
        case .approved:
            return .green
        case .rejected:
            return .red
        case .completed:
            return .purple
        case .cancelled:
            return .orange
        }
    }
}
