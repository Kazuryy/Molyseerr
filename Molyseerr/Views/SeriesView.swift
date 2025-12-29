//
//  SeriesView.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI
import Combine

/// Series page - Dedicated view for browsing TV shows
/// Features: Popular, Upcoming, Available, and Genre-based sliders
struct SeriesView: View {
    @StateObject private var viewModel = SeriesViewModel()
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
                await viewModel.loadSeries()
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)

            Text("Loading TV shows...")
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
                    await viewModel.loadSeries()
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
                    Text("TV Shows")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 24)

                // Available TV Shows Slider
                if !viewModel.availableTV.isEmpty {
                    sliderSection(
                        title: "Available in Library",
                        items: viewModel.availableTV,
                        showAll: {
                            // TODO: Navigate to full available TV list
                        }
                    )
                }

                // Popular TV Shows Slider
                if !viewModel.popularTV.isEmpty {
                    sliderSection(
                        title: "Popular TV Shows",
                        items: viewModel.popularTV,
                        showAll: {
                            // TODO: Navigate to full popular TV list
                        }
                    )
                }

                // Upcoming TV Shows Slider
                if !viewModel.upcomingTV.isEmpty {
                    sliderSection(
                        title: "Upcoming Shows",
                        items: viewModel.upcomingTV,
                        showAll: {
                            // TODO: Navigate to full upcoming TV list
                        }
                    )
                }

                // TV Genres Section
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
                            GenreTVView(genre: genre)
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
class SeriesViewModel: ObservableObject {
    @Published var availableTV: [MediaResult] = []
    @Published var popularTV: [MediaResult] = []
    @Published var upcomingTV: [MediaResult] = []
    @Published var genres: [Genre] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = SeerrService.shared

    func loadSeries() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load all TV sections in parallel using TaskGroup for MainActor isolation
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { @MainActor in
                    let response = try await self.service.getAvailableMedia(type: "tv", page: 1)
                    self.availableTV = Array(response.results.prefix(20))
                }

                group.addTask { @MainActor in
                    let response = try await self.service.getPopularTV(page: 1)
                    self.popularTV = Array(response.results.prefix(20))
                }

                group.addTask { @MainActor in
                    let response = try await self.service.getUpcomingTV(page: 1)
                    self.upcomingTV = Array(response.results.prefix(20))
                }

                group.addTask { @MainActor in
                    self.genres = try await self.service.getTVGenres()
                }

                try await group.waitForAll()
            }
        } catch {
            errorMessage = "Failed to load TV shows: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Genre TV View

struct GenreTVView: View {
    let genre: Genre
    @StateObject private var viewModel = GenreTVViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 300), spacing: 30)
                ], spacing: 30) {
                    ForEach(viewModel.tvShows, id: \.id) { mediaResult in
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
            await viewModel.loadTVShows(genreId: genre.id)
        }
    }
}

@MainActor
class GenreTVViewModel: ObservableObject {
    @Published var tvShows: [MediaResult] = []
    @Published var isLoading = false

    private let service = SeerrService.shared

    func loadTVShows(genreId: Int) async {
        isLoading = true

        do {
            let response = try await service.getTVByGenre(genreId: genreId, page: 1)
            self.tvShows = response.results
        } catch {
            print("Failed to load genre TV shows: \(error)")
        }

        isLoading = false
    }
}

#Preview {
    SeriesView()
        .environmentObject(ConfigManager())
}
