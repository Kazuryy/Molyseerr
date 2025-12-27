//
//  TodayReleasesRow.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import SwiftUI

/// Horizontal row specifically for Today's Releases
/// Uses custom TodayReleaseCard instead of standard MediaCardView
struct TodayReleasesRow: View {
    let title: String
    let items: [CalendarItem]

    // MARK: - Constants
    private let cardSpacing: CGFloat = 40
    private let horizontalPadding: CGFloat = 48
    private let verticalPadding: CGFloat = 30  // Space for focus scale

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
                        TodayReleaseCard(item: item)
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

        TodayReleasesRow(
            title: "Today's Releases",
            items: [
                CalendarItem(
                    type: "movie",
                    tmdbId: 12345,
                    tvdbId: nil,
                    title: "The Amazing Spider-Man",
                    seasonNumber: nil,
                    episodeNumber: nil,
                    episodeTitle: nil,
                    releaseDate: "2025-12-27T20:00:00.000Z",
                    overview: nil,
                    status: "released",
                    hasFile: true,
                    inWatchlist: true,
                    countdown: 3600,
                    posterPath: nil,
                    backdropPath: nil
                ),
                CalendarItem(
                    type: "tv",
                    tmdbId: 67890,
                    tvdbId: 123,
                    title: "Breaking Bad",
                    seasonNumber: 5,
                    episodeNumber: 14,
                    episodeTitle: "Ozymandias",
                    releaseDate: "2025-12-27T21:00:00.000Z",
                    overview: nil,
                    status: "announced",
                    hasFile: false,
                    inWatchlist: false,
                    countdown: 7200,
                    posterPath: nil,
                    backdropPath: nil
                )
            ]
        )
    }
}
