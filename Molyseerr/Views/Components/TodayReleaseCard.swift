//
//  TodayReleaseCard.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import SwiftUI
import Kingfisher

/// Custom card for Today's Releases slider
/// Matches Seerr web TodaysReleaseCard design with tvOS adaptations
/// Source: seerr/src/components/Discover/TodaysReleasesSlider/TodaysReleaseCard.tsx
struct TodayReleaseCard: View {
    let item: CalendarItem

    @FocusState private var isFocused: Bool

    // MARK: - Constants (tvOS scaled from web 208px width)
    private let cardWidth: CGFloat = 450  // 16:9 aspect ratio for tvOS
    private let cardHeight: CGFloat = 253
    private let focusScale: CGFloat = 1.08
    private let cornerRadius: CGFloat = 12
    private let borderWidth: CGFloat = 6

    var body: some View {
        NavigationLink {
            MediaDetailView(mediaResult: item.toMediaResult())
        } label: {
            cardContent
        }
        .buttonStyle(.card)
        .focused($isFocused)
        .scaleEffect(isFocused ? focusScale : 1.0)
        .shadow(radius: isFocused ? 20 : 4, y: isFocused ? 10 : 2)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }

    // MARK: - Main Card Content

    private var cardContent: some View {
        ZStack(alignment: .topLeading) {
            // Background image with gradient overlay
            backgroundImage

            // Status border (left side)
            statusBorder

            // Top badges
            topBadges
                .padding(.top, 12)
                .padding(.horizontal, 12)

            // Bottom content
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                bottomContent
                    .padding(16)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .cornerRadius(cornerRadius)
    }

    // MARK: - Background

    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: item.type == "movie" ? "film" : "tv")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.3))
            )
    }

    private var backgroundImage: some View {
        ZStack {
            // Use backdropPath (16:9) instead of posterPath (2:3)
            if let backdropPath = item.backdropPath {
                // Check if backdropPath is already a full URL (from TVDB) or just a path (from TMDB)
                let imageURL: URL? = {
                    if backdropPath.hasPrefix("http://") || backdropPath.hasPrefix("https://") {
                        // Already a full URL (TVDB), use it directly
                        return URL(string: backdropPath)
                    } else {
                        // TMDB path, build the URL
                        return TMDBImageHelper.imageURL(path: backdropPath, size: .backdropMedium)
                    }
                }()

                if let imageURL = imageURL {
                    KFImage(imageURL)
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: cardWidth, height: cardHeight)
                        .clipped()
                } else {
                    // Invalid URL
                    placeholderImage
                }
            } else if let posterPath = item.posterPath {
                // Fallback to poster if no backdrop
                let imageURL: URL? = {
                    if posterPath.hasPrefix("http://") || posterPath.hasPrefix("https://") {
                        return URL(string: posterPath)
                    } else {
                        return TMDBImageHelper.posterURL(path: posterPath)
                    }
                }()

                if let imageURL = imageURL {
                    KFImage(imageURL)
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: cardWidth, height: cardHeight)
                        .clipped()
                } else {
                    placeholderImage
                }
            } else {
                placeholderImage
            }

            // Gradient overlay (bottom to top for text readability)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.9),
                    Color.black.opacity(0.6),
                    Color.black.opacity(0.3),
                    Color.clear
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
        }
    }

    // MARK: - Status Border

    private var statusBorder: some View {
        Rectangle()
            .fill(statusBorderColor)
            .frame(width: borderWidth)
    }

    private var statusBorderColor: Color {
        switch item.statusColor {
        case .watchlist:
            return Color.yellow
        case .available:
            return Color.green
        case .released:
            return Color.orange
        case .announced:
            return Color.blue
        case .inCinemas:
            return Color.purple
        case .unknown:
            return Color.gray
        }
    }

    // MARK: - Top Badges

    private var topBadges: some View {
        HStack {
            // Type badge (left)
            typeBadge

            Spacer()

            // Watchlist star (right)
            if item.inWatchlist {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
            }
        }
    }

    private var typeBadge: some View {
        Text(item.type == "movie" ? "MOVIE" : "SERIES")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(item.type == "movie" ? Color.Seerr.movieBadge : Color.Seerr.seriesBadge)
                    .opacity(0.8)
            )
    }

    // MARK: - Bottom Content

    private var bottomContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(item.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(2)

            // Episode info (TV only)
            if let episodeLabel = item.episodeLabel, let episodeTitle = item.episodeTitle {
                Text("\(episodeLabel) · \(episodeTitle)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }

            // Time range
            if let timeRange = item.timeRange() {
                Text(timeRange)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            // Status badge (if available)
            if item.hasFile {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                    Text("Available")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.green)
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        HStack(spacing: 40) {
            // Movie example
            TodayReleaseCard(item: CalendarItem(
                type: "movie",
                tmdbId: 12345,
                tvdbId: nil,
                title: "The Amazing Spider-Man Returns",
                seasonNumber: nil,
                episodeNumber: nil,
                episodeTitle: nil,
                releaseDate: "2025-12-27T20:00:00.000Z",
                overview: "A thrilling adventure...",
                status: "released",
                hasFile: true,
                inWatchlist: true,
                countdown: 3600,
                posterPath: nil,
                backdropPath: nil
            ))

            // TV example
            TodayReleaseCard(item: CalendarItem(
                type: "tv",
                tmdbId: 67890,
                tvdbId: 123,
                title: "Breaking Bad",
                seasonNumber: 1,
                episodeNumber: 9,
                episodeTitle: "The One Where Everything Changes",
                releaseDate: "2025-12-27T21:30:00.000Z",
                overview: "An epic episode...",
                status: "announced",
                hasFile: false,
                inWatchlist: false,
                countdown: 7200,
                posterPath: nil,
                backdropPath: nil
            ))
        }
    }
}
