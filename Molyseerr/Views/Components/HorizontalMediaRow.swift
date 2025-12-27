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

    // MARK: - Constants
    private let cardSpacing: CGFloat = 40
    private let horizontalPadding: CGFloat = 48  // Seerr style padding
    private let verticalPadding: CGFloat = 40  // Space for focus scale (10% of 375px card)

    var body: some View {
        let _ = print("🎨 HorizontalMediaRow rendering: \(title) with \(items.count) items")
        return VStack(alignment: .leading, spacing: 20) {
            // Section title
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.leading, horizontalPadding)

            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: cardSpacing) {
                    ForEach(items) { item in
                        MediaCardView(item: item)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)  // Prevent clipping on focus
            }
            .scrollClipDisabled()  // Allow focus scale to overflow
        }
    }
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
