//
//  TVGenreDetailView.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import SwiftUI
import Combine

/// TV Genre detail view - displays TV shows for a specific genre
/// Matches Seerr web app genre detail browsing with infinite scroll
struct TVGenreDetailView: View {
    let genre: Genre

    @StateObject private var viewModel: TVGenreDetailViewModel

    // Grid layout - 6 columns for poster view (like Seerr's vertical cards)
    private let columns = [
        GridItem(.flexible(), spacing: 40),
        GridItem(.flexible(), spacing: 40),
        GridItem(.flexible(), spacing: 40),
        GridItem(.flexible(), spacing: 40),
        GridItem(.flexible(), spacing: 40),
        GridItem(.flexible(), spacing: 40)
    ]

    init(genre: Genre) {
        self.genre = genre
        _viewModel = StateObject(wrappedValue: TVGenreDetailViewModel(genre: genre))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                if viewModel.isLoading && viewModel.shows.isEmpty {
                    loadingView
                } else if let error = viewModel.errorMessage, viewModel.shows.isEmpty {
                    errorView(message: error)
                } else if viewModel.shows.isEmpty {
                    emptyView
                } else {
                    showGrid
                }
            }
        }
        .navigationTitle("\(genre.name) TV Shows")
        .task {
            await viewModel.loadShows()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)

            Text("Loading \(genre.name.lowercased()) shows...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Error")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task {
                    await viewModel.loadShows()
                }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding()
                    .background(Color.Seerr.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tv")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Shows Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("No \(genre.name.lowercased()) shows are available.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var showGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(viewModel.shows) { show in
                    MediaCardView(item: .tv(show))
                        .onAppear {
                            // Load more when approaching end
                            if show.id == viewModel.shows.last?.id {
                                Task {
                                    await viewModel.loadMoreShows()
                                }
                            }
                        }
                }

                // Loading indicator for pagination
                if viewModel.isLoadingMore {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)
                            .padding(.top, 40)
                    }
                    .frame(maxWidth: .infinity)
                    .gridCellColumns(6)
                }
            }
            .padding(48)
        }
    }
}

// MARK: - View Model

@MainActor
class TVGenreDetailViewModel: ObservableObject {
    let genre: Genre

    @Published var shows: [TVResult] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?

    private var currentPage = 0
    private var totalPages = 1
    private var hasLoadedInitial = false

    init(genre: Genre) {
        self.genre = genre
    }

    func loadShows() async {
        guard !hasLoadedInitial, !isLoading else { return }

        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            let response = try await SeerrService.shared.getTVByGenre(genreId: genre.id, page: currentPage)

            // Extract TV shows from MediaResult enum
            shows = response.results.compactMap { mediaResult in
                if case .tv(let show) = mediaResult {
                    return show
                }
                return nil
            }

            totalPages = response.totalPages
            hasLoadedInitial = true

            print("✅ Loaded \(shows.count) shows for genre \(genre.name) (page \(currentPage)/\(totalPages))")
        } catch {
            print("❌ Failed to load shows for genre \(genre.name): \(error)")
            errorMessage = "Failed to load shows: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func loadMoreShows() async {
        // Don't load more if already loading or no more pages
        guard !isLoading, !isLoadingMore, currentPage < totalPages else {
            return
        }

        isLoadingMore = true
        currentPage += 1

        do {
            let response = try await SeerrService.shared.getTVByGenre(genreId: genre.id, page: currentPage)

            // Extract and append shows
            let newShows = response.results.compactMap { mediaResult -> TVResult? in
                if case .tv(let show) = mediaResult {
                    return show
                }
                return nil
            }

            shows.append(contentsOf: newShows)
            totalPages = response.totalPages

            print("✅ Loaded \(newShows.count) more shows for genre \(genre.name) (page \(currentPage)/\(totalPages))")
        } catch {
            print("❌ Failed to load more shows for genre \(genre.name): \(error)")
            // Don't show error for pagination failures, just stop loading
            currentPage -= 1 // Revert page increment
        }

        isLoadingMore = false
    }
}

#Preview {
    let sampleGenre = Genre(
        id: 10759,
        name: "Action & Adventure",
        backdrops: ["/path/to/backdrop.jpg"]
    )

    return NavigationStack {
        TVGenreDetailView(genre: sampleGenre)
    }
    .preferredColorScheme(.dark)
}
