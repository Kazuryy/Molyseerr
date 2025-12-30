//
//  EpisodeCard.swift
//  Molyseerr
//
//  Created by Claude on 30/12/2025.
//

import SwiftUI
import Kingfisher

/// Episode card component inspired by Swiftfin's EpisodeCard
/// Displays episode thumbnail, progress, and metadata
struct EpisodeCard: View {
    let episode: Episode
    let onTap: () -> Void

    @FocusState private var isFocused: Bool

    // Constants
    private let cardWidth: CGFloat = 400
    private let cardHeight: CGFloat = 225

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Episode thumbnail with overlay
            Button {
                onTap()
            } label: {
                ZStack {
                    Color.clear

                    // Episode image
                    if let imageURL = episodeImageURL {
                        KFImage(imageURL)
                            .placeholder {
                                Color.gray.opacity(0.3)
                            }
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fit)  // .fit instead of .fill to avoid inner zoom
                    } else {
                        // Placeholder
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fit)  // .fit instead of .fill
                            .overlay(
                                Image(systemName: "tv")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white.opacity(0.3))
                            )
                    }

                    // Overlay (progress, play icon, watched status)
                    overlayView
                }
                .frame(width: cardWidth, height: cardHeight)
                .cornerRadius(12)
            }
            .buttonStyle(.card)  // Native tvOS CardButtonStyle handles focus/zoom automatically
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            .focused($isFocused)

            // Episode metadata
            EpisodeContent(
                subHeader: episodeLocator,
                header: episode.name ?? "Episode \(episode.episodeNumber ?? 0)",
                content: episodeContent
            )
            .frame(width: cardWidth)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var overlayView: some View {
        ZStack {
            // Progress bar at bottom (if episode is partially watched)
            // TODO: Add progress tracking

            // Watched checkmark (if episode is fully watched)
            // TODO: Add watched status tracking

            // Play icon when focused
            if isFocused {
                Image(systemName: "play.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 10)
            }
        }
    }

    // MARK: - Computed Properties

    /// Episode image URL - handles both TMDB paths and TVDB paths/URLs
    private var episodeImageURL: URL? {
        guard let stillPath = episode.stillPath, !stillPath.isEmpty else {
            print("⚠️ Episode \(episode.id) has no stillPath")
            return nil
        }

        // Check if it's already a full URL (TVDB format - rare)
        if stillPath.hasPrefix("http://") || stillPath.hasPrefix("https://") {
            let url = URL(string: stillPath)
            print("🖼️ Episode \(episode.id) using TVDB full URL: \(stillPath)")
            return url
        }

        // Check if it's a TVDB path (starts with /banners/)
        if stillPath.hasPrefix("/banners/") {
            let tvdbURL = "https://artworks.thetvdb.com\(stillPath)"
            let url = URL(string: tvdbURL)
            print("🖼️ Episode \(episode.id) using TVDB path: \(stillPath) → \(tvdbURL)")
            return url
        }

        // Otherwise, it's a TMDB path
        let url = TMDBImageHelper.stillURL(path: stillPath)
        print("🖼️ Episode \(episode.id) using TMDB path: \(stillPath) → \(url?.absoluteString ?? "nil")")
        return url
    }

    private var episodeLocator: String {
        if let seasonNum = episode.seasonNumber, let episodeNum = episode.episodeNumber {
            return "S\(seasonNum) E\(episodeNum)"
        }
        return "Episode"
    }

    private var episodeContent: String {
        // Check if episode has aired
        if let airDate = episode.airDate, !airDate.isEmpty {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
            if let date = formatter.date(from: airDate), date > Date() {
                // Episode hasn't aired yet
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .medium
                return "Airs \(displayFormatter.string(from: date))"
            }
        }

        // Return overview if available
        return episode.overview ?? "No overview available"
    }
}

// MARK: - Episode Content Component

/// Episode metadata text component
struct EpisodeContent: View {
    let subHeader: String
    let header: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Episode locator (S1 E5)
            Text(subHeader)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255)) // gray-400

            // Episode title
            Text(header)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)

            // Episode description or air date
            Text(content)
                .font(.system(size: 20))
                .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255)) // gray-400
                .lineLimit(3)
        }
    }
}
