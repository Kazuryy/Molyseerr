//
//  HorizontalMediaRow.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import SwiftUI

/// Horizontal scrollable row of media cards
/// Apple TV+ style with title and horizontal scroll
struct HorizontalMediaRow: View {
    let title: String
    let items: [MediaResult]
    var isLoading: Bool = false  // Show skeleton loaders when loading

    // MARK: - Constants
    private let cardSpacing: CGFloat = 40
    private let horizontalPadding: CGFloat = 60  // Balanced for sidebar layout
    private let verticalPadding: CGFloat = 40  // Space for focus scale (10% of 375px card)
    private let skeletonCount: Int = 6  // Number of skeleton cards to show

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section title
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.leading, horizontalPadding)

            // Performant horizontal scroll using UICollectionView
            // Fixes tvOS 18 _UIFocusRegionEvaluator bug by using UIKit instead of SwiftUI LazyHStack
            if isLoading && items.isEmpty {
                // Skeleton loading state
                PerformantHStack(
                    items: Array(0..<skeletonCount).map { SkeletonItem(id: $0) },
                    itemWidth: 250,
                    itemHeight: 375,
                    spacing: cardSpacing,
                    horizontalPadding: horizontalPadding,
                    verticalPadding: verticalPadding
                ) { _ in
                    SkeletonCardView()
                }
                .frame(height: 375 + (verticalPadding * 2))
            } else {
                // Actual content with real UICollectionView
                PerformantHStack(
                    items: items,
                    itemWidth: 250,
                    itemHeight: 375,
                    spacing: cardSpacing,
                    horizontalPadding: horizontalPadding,
                    verticalPadding: verticalPadding
                ) { item in
                    MediaCardViewSimple(item: item)
                }
                .frame(height: 375 + (verticalPadding * 2))
            }
        }
    }
}

// MARK: - Skeleton Item (for loading state)

private struct SkeletonItem: Identifiable, Hashable {
    let id: Int
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 60) {
            // First row
            HorizontalMediaRow(
                title: "Trending Now",
                items: [
                    .movie(MovieResult(
                        id: 1,
                        adult: false,
                        backdropPath: nil,
                        posterPath: nil,
                        genreIds: nil,
                        originalLanguage: "en",
                        originalTitle: "Movie 1",
                        overview: nil,
                        popularity: nil,
                        releaseDate: nil,
                        firstAirDate: nil,
                        title: "Movie 1",
                        name: nil,
                        originCountry: nil,
                        originalName: nil,
                        video: nil,
                        voteAverage: nil,
                        voteCount: nil,
                        mediaType: "movie",
                        mediaInfo: nil
                    )),
                    .movie(MovieResult(
                        id: 2,
                        adult: false,
                        backdropPath: nil,
                        posterPath: nil,
                        genreIds: nil,
                        originalLanguage: "en",
                        originalTitle: "Movie 2",
                        overview: nil,
                        popularity: nil,
                        releaseDate: nil,
                        firstAirDate: nil,
                        title: "Movie 2",
                        name: nil,
                        originCountry: nil,
                        originalName: nil,
                        video: nil,
                        voteAverage: nil,
                        voteCount: nil,
                        mediaType: "movie",
                        mediaInfo: nil
                    )),
                    .tv(TVResult(
                        id: 3,
                        backdropPath: nil,
                        posterPath: nil,
                        genreIds: nil,
                        originalLanguage: "en",
                        originalName: "Series 1",
                        overview: nil,
                        popularity: nil,
                        firstAirDate: nil,
                        name: "Series 1",
                        voteAverage: nil,
                        voteCount: nil,
                        originCountry: nil,
                        mediaType: "tv",
                        mediaInfo: nil
                    ))
                ]
            )

            Spacer()
        }
    }
}
