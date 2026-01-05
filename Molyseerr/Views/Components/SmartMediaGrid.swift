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
        // Calculate total rows needed
        let totalRows = (items.count + columnsPerRow - 1) / columnsPerRow

        LazyVStack(spacing: spacing) {
            ForEach(0..<totalRows, id: \.self) { rowIndex in
                let rowItems = getRowItems(rowIndex: rowIndex)
                HStack(spacing: spacing) {
                    ForEach(Array(rowItems.enumerated()), id: \.offset) { colIndex, item in
                        MediaCardView(item: item)
                            .id("\(rowIndex)-\(colIndex)")  // Unique ID combining row and column
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

    /// Get items for a specific row (computed on-demand for lazy loading)
    private func getRowItems(rowIndex: Int) -> [MediaResult] {
        let startIndex = rowIndex * columnsPerRow
        let endIndex = min(startIndex + columnsPerRow, items.count)
        guard startIndex < items.count else { return [] }
        return Array(items[startIndex..<endIndex])
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
