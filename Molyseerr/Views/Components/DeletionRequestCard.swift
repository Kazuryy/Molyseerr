//
//  DeletionRequestCard.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import SwiftUI
import Kingfisher

/// Large detailed deletion request card for list view
/// Reference: Seerr DeletionRequestCard component
/// Full-size card with all details and admin actions
struct DeletionRequestCard: View {

    // MARK: - Properties

    let deletionRequest: DeletionRequest
    let userVote: Bool?
    let onVoteKeep: () async -> Void
    let onVoteRemove: () async -> Void
    let onRemoveVote: () async -> Void
    let onExecute: () async -> Void
    let onCancel: () async -> Void

    @FocusState private var isFocused: Bool
    @State private var isProcessing: Bool = false

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background image
            backdropImage

            // Content overlay
            HStack(alignment: .top, spacing: 32) {
                // Left section: Poster + Title + Reason
                leftSection

                // Middle section: Metadata + Progress
                middleSection

                Spacer()

                // Right section: Actions
                rightSection
            }
            .padding(32)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.8),
                        Color.black.opacity(0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(height: 320)
        .cornerRadius(16)
        .focusable()
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(color: isFocused ? .white.opacity(0.2) : .clear, radius: 16)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }

    // MARK: - Subviews

    /// Backdrop image
    private var backdropImage: some View {
        Group {
            if let backdropURL = deletionRequest.backdropURL {
                KFImage(URL(string: backdropURL))
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 320)
                    .clipped()
                    .blur(radius: 8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
        }
    }

    /// Left section: Poster + Info
    private var leftSection: some View {
        HStack(spacing: 20) {
            // Poster thumbnail
            if let posterURL = deletionRequest.posterURL {
                KFImage(URL(string: posterURL))
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 180)
                    .cornerRadius(8)
            }

            // Title + Reason
            VStack(alignment: .leading, spacing: 12) {
                // Status badge
                Text(deletionRequest.status.displayName.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.9))
                    .cornerRadius(6)

                // Title
                Text(deletionRequest.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(2)

                // Media type
                Text(deletionRequest.mediaType == "movie" ? "Movie" : "Series")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                // Reason
                if let reason = deletionRequest.reason, !reason.isEmpty {
                    Text(reason)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(3)
                }

                // Requested by
                Text("Requested by \(deletionRequest.requestedBy.displayName)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }

    /// Middle section: Progress + Voting
    private var middleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Voting end time
            if let votingEndsAt = deletionRequest.votingEndsAtFormatted {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                    Text(votingEndsAt)
                }
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
            }

            // Vote progress
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 16) {
                    Label("\(deletionRequest.votesAgainst)", systemImage: "hand.thumbsup.fill")
                        .font(.body)
                        .foregroundColor(.green)

                    Spacer()

                    Label("\(deletionRequest.votesFor)", systemImage: "hand.thumbsdown.fill")
                        .font(.body)
                        .foregroundColor(.red)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background (remove)
                        Rectangle()
                            .fill(Color.red.opacity(0.5))

                        // Foreground (keep)
                        Rectangle()
                            .fill(Color.green.opacity(0.8))
                            .frame(width: geometry.size.width * CGFloat(deletionRequest.keepProgress))
                    }
                }
                .frame(height: 12)
                .cornerRadius(6)

                // Vote percentage
                Text("\(Int(deletionRequest.voteProgress * 100))% for removal")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            // User vote status
            if let userVote = userVote {
                HStack(spacing: 8) {
                    Image(systemName: userVote ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(userVote ? .red : .green)
                    Text("You voted to \(userVote ? "remove" : "keep") this")
                        .font(.body)
                }
            }
        }
        .frame(width: 300)
    }

    /// Right section: Action buttons
    private var rightSection: some View {
        VStack(alignment: .trailing, spacing: 12) {
            // Vote buttons (if voting active)
            if deletionRequest.isVotingActive == true {
                voteButtons
            }

            Spacer()

            // Admin buttons
            if deletionRequest.status == .approved {
                executeButton
            }

            if deletionRequest.status == .voting || deletionRequest.status == .pending {
                cancelButton
            }
        }
    }

    /// Vote buttons
    private var voteButtons: some View {
        VStack(spacing: 12) {
            // Keep button
            Button(action: {
                Task {
                    isProcessing = true
                    await onVoteKeep()
                    isProcessing = false
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: userVote == false ? "checkmark.circle.fill" : "checkmark.circle")
                    Text("Keep")
                }
                .frame(width: 140)
                .padding(.vertical, 12)
                .background(userVote == false ? Color.green : Color.white.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)

            // Remove button
            Button(action: {
                Task {
                    isProcessing = true
                    await onVoteRemove()
                    isProcessing = false
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: userVote == true ? "xmark.circle.fill" : "xmark.circle")
                    Text("Remove")
                }
                .frame(width: 140)
                .padding(.vertical, 12)
                .background(userVote == true ? Color.red : Color.white.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)

            // Remove vote button (if user has voted)
            if userVote != nil {
                Button(action: {
                    Task {
                        isProcessing = true
                        await onRemoveVote()
                        isProcessing = false
                    }
                }) {
                    Text("Clear Vote")
                        .frame(width: 140)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white.opacity(0.6))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
            }
        }
    }

    /// Execute deletion button (admin only)
    private var executeButton: some View {
        Button(action: {
            Task {
                isProcessing = true
                await onExecute()
                isProcessing = false
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill")
                Text("Execute")
            }
            .frame(width: 140)
            .padding(.vertical, 12)
            .background(Color.red.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
    }

    /// Cancel button
    private var cancelButton: some View {
        Button(action: {
            Task {
                isProcessing = true
                await onCancel()
                isProcessing = false
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle")
                Text("Cancel")
            }
            .frame(width: 140)
            .padding(.vertical, 12)
            .background(Color.orange.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
    }

    // MARK: - Helpers

    /// Status color
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
