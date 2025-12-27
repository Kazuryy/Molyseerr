//
//  TVGenresRow.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import SwiftUI
import Combine

/// Horizontal scrolling row of TV genre cards
/// Displayed as a slider in the DiscoverView, matching Seerr web app
struct TVGenresRow: View {
    let title: String
    @StateObject private var viewModel = TVGenresRowViewModel()

    // Vertical padding to prevent clipping when cards zoom (FOCUS_SYSTEM.md)
    // Card height 270 * zoom 0.08 / 2 + margin = ~25pt
    private let verticalPadding: CGFloat = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.leading, 48)

            if viewModel.isLoading {
                // Loading state
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Loading genres...")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.leading, 48)
            } else if let error = viewModel.errorMessage {
                // Error state
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.leading, 48)
            } else if viewModel.genres.isEmpty {
                // Empty state
                Text("No genres available")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.leading, 48)
            } else {
                // Genre cards scroll view
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 30) {
                        ForEach(viewModel.genres) { genre in
                            NavigationLink {
                                TVGenreDetailView(genre: genre)
                            } label: {
                                GenreCard(genre: genre)
                            }
                            .buttonStyle(.card)
                        }
                    }
                    .padding(.horizontal, 48)
                    .padding(.vertical, verticalPadding)  // Prevent clipping
                }
                .scrollClipDisabled()  // Allow content to overflow
            }
        }
        .task {
            await viewModel.loadGenres()
        }
    }
}

// MARK: - View Model

@MainActor
class TVGenresRowViewModel: ObservableObject {
    @Published var genres: [Genre] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var hasLoaded = false

    func loadGenres() async {
        guard !hasLoaded, !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            genres = try await SeerrService.shared.getTVGenres()
            hasLoaded = true
            print("✅ TVGenresRow: Loaded \(genres.count) genres")
        } catch {
            print("❌ TVGenresRow: Failed to load genres: \(error)")
            errorMessage = "Failed to load genres"
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        ZStack {
            Color.black.ignoresSafeArea()
            TVGenresRow(title: "TV Genres")
        }
    }
    .preferredColorScheme(.dark)
}
