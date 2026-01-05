//
//  MediaCardView.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import SwiftUI
import Kingfisher

/// Media card component for displaying movie/TV show posters
/// Follows Apple TV+ design guidelines with focus effects
struct MediaCardView: View {
    let item: MediaResult

    @FocusState private var isFocused: Bool

    // MARK: - Constants
    private let cardWidth: CGFloat = 250
    private let cardHeight: CGFloat = 375  // 2:3 ratio
    private let focusScale: CGFloat = 1.05
    private let cornerRadius: CGFloat = 8

    var body: some View {
        NavigationLink {
            MediaDetailView(mediaResult: item)
        } label: {
            VStack(spacing: 0) {
                // Poster placeholder
                posterView

                // Optional: Title below poster
                // titleView
            }
        }
        .buttonStyle(.card)
        .focused($isFocused)
        .scaleEffect(isFocused ? focusScale : 1.0)
        .shadow(radius: isFocused ? 10 : 2, y: isFocused ? 5 : 1)
        .compositingGroup()
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }

    // MARK: - Subviews

    private var posterView: some View {
        ZStack {
            // Poster image using Kingfisher (TECH_RULES.md: Use KFImage, not AsyncImage)
            if let posterURL = TMDBImageHelper.posterURL(path: item.posterPath) {
                KFImage(posterURL)
                    .placeholder {
                        // Skeleton shimmer placeholder while loading
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: cardWidth, height: cardHeight)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(Color.gray.opacity(0.3))
                                    .shimmer()
                            )
                    }
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: cardWidth * 2, height: cardHeight * 2)))
                    .cacheMemoryOnly()
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()
                    .cornerRadius(cornerRadius)
            } else {
                // Fallback if no poster available
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: item.mediaType == .movie ? "film" : "tv")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.3))
                    )
            }

            // Top badges overlay
            VStack {
                HStack(alignment: .top) {
                    // Media type badge (top-left)
                    mediaTypeIcon

                    Spacer()

                    // Status badge (top-right)
                    if let mediaInfo = item.mediaInfo,
                       mediaInfo.status != .unknown {
                        StatusBadgeMini(status: mediaInfo.status, shrink: true)
                    }
                }
                .padding(12)
                Spacer()
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }

    private var mediaTypeIcon: some View {
        Text(item.mediaType == .movie ? "MOVIE" : "SERIES")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(item.mediaType == .movie ? Color.Seerr.movieBadge : Color.Seerr.seriesBadge)
                    .opacity(0.8)
            )
    }

    // Uncomment if you want title below poster
    /*
    private var titleView: some View {
        Text(item.title)
            .font(.headline)
            .foregroundColor(.white)
            .lineLimit(2)
            .frame(width: cardWidth)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }
    */
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        HStack(spacing: 40) {
            // Movie card
            MediaCardView(item: .movie(MovieResult(
                id: 1,
                adult: false,
                backdropPath: nil,
                posterPath: nil,
                genreIds: nil,
                originalLanguage: "en",
                originalTitle: "Test Movie",
                overview: "A test movie",
                popularity: 100,
                releaseDate: "2025-01-01",
                firstAirDate: nil,
                title: "Test Movie",
                name: nil,
                originCountry: nil,
                originalName: nil,
                video: false,
                voteAverage: 8.5,
                voteCount: 1000,
                mediaType: "movie",
                mediaInfo: nil
            )))

            // TV card
            MediaCardView(item: .tv(TVResult(
                id: 2,
                backdropPath: nil,
                posterPath: nil,
                genreIds: nil,
                originalLanguage: "en",
                originalName: "Test Series",
                overview: "A test series",
                popularity: 150,
                firstAirDate: "2025-01-01",
                name: "Test Series",
                voteAverage: 9.0,
                voteCount: 2000,
                originCountry: nil,
                mediaType: "tv",
                mediaInfo: nil
            )))
        }
    }
}
