//
//  MoviesView.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI
import Combine

/// Movies page - Dedicated view for browsing movies
/// Features: Popular, Upcoming, Available, and Genre-based sliders
struct MoviesView: View {
    @StateObject private var viewModel = MoviesViewModel()
    @EnvironmentObject var configManager: ConfigManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Group {
                    if viewModel.isLoading {
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(message: errorMessage)
                    } else {
                        contentView
                    }
                }
            }
            .task {
                await viewModel.loadMovies()
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)

            Text("Loading movies...")
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
        .padding()
    }

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Movies")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 24)

                // Available Movies Slider
                if !viewModel.availableMovies.isEmpty {
                    sliderSection(
                        title: "Available in Library",
                        items: viewModel.availableMovies,
                        showAll: {
                            // TODO: Navigate to full available movies list
                        }
                    )
                }

                // Popular Movies Slider
                if !viewModel.popularMovies.isEmpty {
                    sliderSection(
                        title: "Popular Movies",
                        items: viewModel.popularMovies,
                        showAll: {
                            // TODO: Navigate to full popular movies list
                        }
                    )
                }

                // Upcoming Movies Slider
                if !viewModel.upcomingMovies.isEmpty {
                    sliderSection(
                        title: "Upcoming Releases",
                        items: viewModel.upcomingMovies,
                        showAll: {
                            // TODO: Navigate to full upcoming movies list
                        }
                    )
                }

                // Movie Genres Section
                if !viewModel.genres.isEmpty {
                    genresSection
                }
            }
        }
    }

    private func sliderSection(title: String, items: [MediaResult], showAll: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                Button {
                    showAll()
                } label: {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 48)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    ForEach(items, id: \.id) { mediaResult in
                        NavigationLink {
                            MediaDetailView(mediaResult: mediaResult)
                        } label: {
                            MediaCardView(item: mediaResult)
                                .frame(width: 300)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 48)
            }
            .frame(height: 450)
        }
        .padding(.bottom, 40)
    }

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Browse by Genre")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 48)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    ForEach(viewModel.genres, id: \.id) { genre in
                        NavigationLink {
                            GenreMoviesView(genre: genre)
                        } label: {
                            GenreCard(genre: genre)
                        }
                        .buttonStyle(.card)
                    }
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 30)  // Prevent clipping when cards zoom
            }
            .scrollClipDisabled()  // Allow content to overflow
        }
        .padding(.bottom, 40)
    }
}

// MARK: - ViewModel

@MainActor
class MoviesViewModel: ObservableObject {
    @Published var availableMovies: [MediaResult] = []
    @Published var popularMovies: [MediaResult] = []
    @Published var upcomingMovies: [MediaResult] = []
    @Published var genres: [Genre] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = SeerrService.shared

    func loadMovies() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load all movie sections in parallel using TaskGroup for MainActor isolation
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { @MainActor in
                    let response = try await self.service.getAvailableMedia(type: "movie", page: 1)
                    self.availableMovies = Array(response.results.prefix(20))
                }

                group.addTask { @MainActor in
                    let response = try await self.service.getPopularMovies(page: 1)
                    self.popularMovies = Array(response.results.prefix(20))
                }

                group.addTask { @MainActor in
                    let response = try await self.service.getUpcomingMovies(page: 1)
                    self.upcomingMovies = Array(response.results.prefix(20))
                }

                group.addTask { @MainActor in
                    self.genres = try await self.service.getMovieGenres()
                }

                try await group.waitForAll()
            }
        } catch {
            errorMessage = "Failed to load movies: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Genre Movies View

struct GenreMoviesView: View {
    let genre: Genre
    @StateObject private var viewModel = GenreMoviesViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 300), spacing: 30)
                ], spacing: 30) {
                    ForEach(viewModel.movies, id: \.id) { mediaResult in
                        NavigationLink {
                            MediaDetailView(mediaResult: mediaResult)
                        } label: {
                            MediaCardView(item: mediaResult)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(48)
            }
        }
        .navigationTitle(genre.name)
        .task {
            await viewModel.loadMovies(genreId: genre.id)
        }
    }
}

@MainActor
class GenreMoviesViewModel: ObservableObject {
    @Published var movies: [MediaResult] = []
    @Published var isLoading = false

    private let service = SeerrService.shared

    func loadMovies(genreId: Int) async {
        isLoading = true

        do {
            let response = try await service.getMoviesByGenre(genreId: genreId, page: 1)
            self.movies = response.results
        } catch {
            print("Failed to load genre movies: \(error)")
        }

        isLoading = false
    }
}

#Preview {
    MoviesView()
        .environmentObject(ConfigManager())
}
