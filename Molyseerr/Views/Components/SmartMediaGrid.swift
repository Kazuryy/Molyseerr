//
//  SmartMediaGrid.swift
//  Molyseerr
//
//  Created by Claude on 02/01/2026.
//

import SwiftUI

/// Smart media grid with improved tvOS focus navigation
/// Each row is a focus section for better vertical navigation
struct SmartMediaGrid: View {
    let items: [MediaResult]
    let columnsPerRow: Int
    let spacing: CGFloat
    let horizontalPadding: CGFloat
    let onItemAppear: ((MediaResult) -> Void)?

    init(
        items: [MediaResult],
        columnsPerRow: Int = 5,
        spacing: CGFloat = 50,
        horizontalPadding: CGFloat = 48,
        onItemAppear: ((MediaResult) -> Void)? = nil
    ) {
        self.items = items
        self.columnsPerRow = columnsPerRow
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.onItemAppear = onItemAppear
    }

    var body: some View {
        let rows = stride(from: 0, to: items.count, by: columnsPerRow).map { rowIndex in
            Array(items[rowIndex..<min(rowIndex + columnsPerRow, items.count)])
        }

        VStack(spacing: spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, rowItems in
                HStack(spacing: spacing) {
                    ForEach(rowItems) { item in
                        MediaCardView(item: item)
                            .onAppear {
                                onItemAppear?(item)
                            }
                    }

                    // Add spacers for incomplete rows to maintain alignment
                    if rowItems.count < columnsPerRow {
                        ForEach(0..<(columnsPerRow - rowItems.count), id: \.self) { _ in
                            Color.clear
                                .frame(width: 250, height: 375)
                        }
                    }
                }
                .focusSection()  // Each row is a focus section for smart navigation
            }
        }
        .padding(.horizontal, horizontalPadding)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            SmartMediaGrid(
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
                    ))
                ]
            )
        }
    }
}
