//
//  CinematicHeaderView.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI
import Kingfisher

/// Cinematic header with backdrop, poster, title, and action buttons
/// Inspired by Swiftfin's CinematicHeaderView with Seerr styling
struct CinematicHeaderView: View {
    let backdropPath: String?
    let posterPath: String?
    let title: String
    let tagline: String?
    let overview: String?
    let year: String?
    let runtime: String?
    let certification: String?
    let genres: [Genre]?
    let voteAverage: Double?
    let mediaInfo: MediaInfo?
    let mediaType: MediaType

    var onRequest: () -> Void
    var onPlayTrailer: (() -> Void)?
    var onToggleWatchlist: (() -> Void)?

    // Constants
    private let backdropHeight: CGFloat = 900
    private let posterWidth: CGFloat = 300
    private let posterHeight: CGFloat = 450
    private let horizontalPadding: CGFloat = 90

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Backdrop with gradient
                backdropView(width: geometry.size.width)

                // Content overlay
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()

                    HStack(alignment: .bottom, spacing: 40) {
                        // Poster
                        posterView

                        // Info section
                        VStack(alignment: .leading, spacing: 20) {
                            // Title
                            Text(title)
                                .font(.system(size: 60, weight: .bold))
                                .foregroundColor(.white)
                                .lineSpacing(-4)
                                .shadow(color: .black.opacity(0.8), radius: 10)

                            // Tagline
                            if let tagline = tagline, !tagline.isEmpty {
                                Text(tagline)
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .italic()
                                    .shadow(color: .black.opacity(0.6), radius: 8)
                            }

                            // Metadata row
                            metadataRow

                            // Genres
                            genresRow

                            // Overview (truncated)
                            if let overview = overview, !overview.isEmpty {
                                Text(overview)
                                    .font(.system(size: 26))
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineSpacing(4)
                                    .lineLimit(4)
                                    .shadow(color: .black.opacity(0.6), radius: 8)
                                    .padding(.top, 8)
                            }

                            // Action buttons
                            actionButtons
                                .padding(.top, 20)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 60)
                }
            }
            .frame(width: geometry.size.width, height: backdropHeight)
        }
        .frame(height: backdropHeight)
    }

    // MARK: - Subviews

    private func backdropView(width: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            // Backdrop image
            if let backdropURL = TMDBImageHelper.backdropURL(path: backdropPath, size: .original) {
                KFImage(backdropURL)
                    .placeholder {
                        Color(red: 0.1, green: 0.12, blue: 0.16)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: backdropHeight)
                    .clipped()
            } else {
                Color(red: 0.1, green: 0.12, blue: 0.16)
                    .frame(width: width, height: backdropHeight)
            }

            // Gradient overlay for text readability (inspired by Seerr webapp)
            // Goes from semi-transparent at top to fully opaque at bottom
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.47),
                    Color(red: 17/255, green: 24/255, blue: 39/255).opacity(1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var posterView: some View {
        Group {
            if let posterURL = TMDBImageHelper.posterURL(path: posterPath, size: .original) {
                KFImage(posterURL)
                    .placeholder {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(ProgressView().scaleEffect(1.5))
                    }
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fit)
                    .frame(width: posterWidth, height: posterHeight)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.6), radius: 30, x: 0, y: 15)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: posterWidth, height: posterHeight)
                    .overlay(
                        Image(systemName: mediaType == .movie ? "film" : "tv")
                            .font(.system(size: 100))
                            .foregroundColor(.white.opacity(0.3))
                    )
                    .shadow(color: .black.opacity(0.6), radius: 30, x: 0, y: 15)
            }
        }
    }

    private var metadataRow: some View {
        HStack(spacing: 16) {
            // Status badge
            if let mediaInfo = mediaInfo {
                HeaderStatusBadge(status: mediaInfo.status)
            }

            // Year
            if let year = year {
                Text(year)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.6), radius: 8)
            }

            // Certification
            if let certification = certification, !certification.isEmpty {
                Text(certification)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.2))
                    )
                    .shadow(color: .black.opacity(0.6), radius: 8)
            }

            // Runtime
            if let runtime = runtime {
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 5, height: 5)

                Text(runtime)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.6), radius: 8)
            }

            // Rating
            if let rating = voteAverage, rating > 0 {
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 5, height: 5)

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.yellow)

                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .shadow(color: .black.opacity(0.6), radius: 8)
            }
        }
    }

    private var genresRow: some View {
        HStack(spacing: 12) {
            if let genres = genres {
                ForEach(Array(genres.prefix(4))) { genre in
                    Text(genre.name)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.6), radius: 8)
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 32) {  // Increased from 20 to 32 to prevent overlap when focused
            // Request button (primary action)
            if canRequest {
                Button {
                    onRequest()
                } label: {
                    Label("Request", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.actionPrimary)
            }

            // Watchlist button
            if let onToggleWatchlist = onToggleWatchlist {
                Button {
                    onToggleWatchlist()
                } label: {
                    Label("My List", systemImage: "plus")
                }
                .buttonStyle(.actionSecondary)
            }

            // Trailer button
            if let onPlayTrailer = onPlayTrailer {
                Button {
                    onPlayTrailer()
                } label: {
                    Label("Trailer", systemImage: "play.circle")
                }
                .buttonStyle(.actionSecondary)
            }
        }
    }

    // MARK: - Helpers

    private var canRequest: Bool {
        guard let mediaInfo = mediaInfo else { return true }
        return mediaInfo.status != .available && mediaInfo.status != .pending && mediaInfo.status != .processing
    }
}

// MARK: - Header Status Badge

private struct HeaderStatusBadge: View {
    let status: MediaStatus

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .font(.system(size: 20))

            Text(statusText)
                .font(.system(size: 24, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(statusColor)
        )
        .shadow(color: .black.opacity(0.6), radius: 8)
    }

    private var statusIcon: String {
        switch status {
        case .available:
            return "checkmark.circle.fill"
        case .pending, .processing:
            return "clock.fill"
        case .partiallyAvailable:
            return "circle.lefthalf.filled"
        case .blacklisted, .deleted:
            return "xmark.circle.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }

    private var statusText: String {
        switch status {
        case .available:
            return "Available"
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .partiallyAvailable:
            return "Partial"
        case .blacklisted:
            return "Blacklisted"
        case .deleted:
            return "Deleted"
        case .unknown:
            return "Unknown"
        }
    }

    private var statusColor: Color {
        switch status {
        case .available:
            return Color.Seerr.statusAvailable
        case .pending:
            return Color.Seerr.statusPending
        case .processing:
            return Color.Seerr.statusProcessing
        case .partiallyAvailable:
            return Color.orange
        case .blacklisted, .deleted:
            return Color.Seerr.statusError
        case .unknown:
            return Color.gray
        }
    }
}
