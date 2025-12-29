//
//  StudioDetailView.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI
import Combine
import Kingfisher

/// Studio detail view - displays movies from a specific studio
/// Matches Seerr web app studio detail browsing with infinite scroll
struct StudioDetailView: View {
    let studio: Company

    @StateObject private var viewModel: StudioDetailViewModel

    // Grid layout - 6 columns for poster view (like Seerr's vertical cards)
    private let columns = [
        GridItem(.flexible(), spacing: 50),
        GridItem(.flexible(), spacing: 50),
        GridItem(.flexible(), spacing: 50),
        GridItem(.flexible(), spacing: 50),
        GridItem(.flexible(), spacing: 50),
        GridItem(.flexible(), spacing: 50)
    ]

    init(studio: Company) {
        self.studio = studio
        _viewModel = StateObject(wrappedValue: StudioDetailViewModel(studio: studio))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with studio logo
                studioHeader

                // Content
                Group {
                    if viewModel.isLoading && viewModel.movies.isEmpty {
                        loadingView
                    } else if let error = viewModel.errorMessage, viewModel.movies.isEmpty {
                        errorView(message: error)
                    } else if viewModel.movies.isEmpty {
                        emptyView
                    } else {
                        movieGrid
                    }
                }
            }
        }
        .task {
            await viewModel.loadMovies()
        }
    }

    // MARK: - Subviews

    private var studioHeader: some View {
        VStack(spacing: 0) {
            if let logoURL = studio.logoURL {
                KFImage(logoURL)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .padding(.horizontal, 48)
            }
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.8),
                    Color.black.opacity(0.4)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)

            Text("Loading movies from \(studio.name)...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
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
                    await viewModel.loadMovies()
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
        .frame(maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "film")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Movies Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("No movies from \(studio.name) are available.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
    }

    private var movieGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 50) {
                ForEach(viewModel.movies) { movie in
                    MediaCardView(item: .movie(movie))
                        .onAppear {
                            // Load more when approaching end
                            if movie.id == viewModel.movies.last?.id {
                                Task {
                                    await viewModel.loadMoreMovies()
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
class StudioDetailViewModel: ObservableObject {
    let studio: Company

    @Published var movies: [MovieResult] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?

    private var currentPage = 0
    private var totalPages = 1
    private var hasLoadedInitial = false

    init(studio: Company) {
        self.studio = studio
    }

    func loadMovies() async {
        guard !hasLoadedInitial, !isLoading else { return }

        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            let response = try await SeerrService.shared.getMoviesByStudio(studioId: studio.id, page: currentPage)

            // Extract movies from MediaResult enum
            movies = response.results.compactMap { mediaResult in
                if case .movie(let movie) = mediaResult {
                    return movie
                }
                return nil
            }

            totalPages = response.totalPages
            hasLoadedInitial = true

            print("✅ Loaded \(movies.count) movies for studio \(studio.name) (page \(currentPage)/\(totalPages))")
        } catch {
            print("❌ Failed to load movies for studio \(studio.name): \(error)")
            errorMessage = "Failed to load movies: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func loadMoreMovies() async {
        // Don't load more if already loading or no more pages
        guard !isLoading, !isLoadingMore, currentPage < totalPages else {
            return
        }

        isLoadingMore = true
        currentPage += 1

        do {
            let response = try await SeerrService.shared.getMoviesByStudio(studioId: studio.id, page: currentPage)

            // Extract and append movies
            let newMovies = response.results.compactMap { mediaResult -> MovieResult? in
                if case .movie(let movie) = mediaResult {
                    return movie
                }
                return nil
            }

            movies.append(contentsOf: newMovies)
            totalPages = response.totalPages

            print("✅ Loaded \(newMovies.count) more movies for studio \(studio.name) (page \(currentPage)/\(totalPages))")
        } catch {
            print("❌ Failed to load more movies for studio \(studio.name): \(error)")
            // Don't show error for pagination failures, just stop loading
            currentPage -= 1 // Revert page increment
        }

        isLoadingMore = false
    }
}

#Preview {
    NavigationStack {
        StudioDetailView(studio: Company.studios[0])
    }
    .preferredColorScheme(.dark)
}
