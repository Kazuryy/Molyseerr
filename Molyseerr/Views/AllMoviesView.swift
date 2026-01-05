//
//  AllMoviesView.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI
import Combine

/// All Movies view with vertical grid and comprehensive filtering
/// Displays all movies with infinite scroll pagination
struct AllMoviesView: View {
    let category: MovieCategory
    @StateObject private var viewModel: AllMoviesViewModel
    @StateObject private var filterViewModel = FilterViewModel(mediaType: FilterMediaType.movie)
    @EnvironmentObject var configManager: ConfigManager
    @State private var showFilterSheet = false

    init(category: MovieCategory) {
        self.category = category
        _viewModel = StateObject(wrappedValue: AllMoviesViewModel(category: category))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Seerr.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with Filter Button
                    headerSection

                    // Content
                    Group {
                        if viewModel.isLoading && viewModel.movies.isEmpty {
                            loadingView
                        } else if let errorMessage = viewModel.errorMessage, viewModel.movies.isEmpty {
                            errorView(message: errorMessage)
                        } else {
                            contentView
                        }
                    }
                }
            }
            .task {
            await viewModel.loadMovies(filters: filterViewModel)
            await filterViewModel.loadGenres()
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterView(filterViewModel: filterViewModel)
        }
        .onChange(of: filterViewModel.sortBy) { _, _ in
            Task {
                await viewModel.reloadWithFilters(filters: filterViewModel)
            }
        }
        .onChange(of: filterViewModel.selectedGenres) { _, _ in
            Task {
                await viewModel.reloadWithFilters(filters: filterViewModel)
            }
        }
        .onChange(of: filterViewModel.isRuntimeFilterActive) { _, _ in
            Task {
                await viewModel.reloadWithFilters(filters: filterViewModel)
            }
        }
        .onChange(of: filterViewModel.isRatingFilterActive) { _, _ in
            Task {
                await viewModel.reloadWithFilters(filters: filterViewModel)
            }
        }
        .onChange(of: filterViewModel.isVoteCountFilterActive) { _, _ in
            Task {
                await viewModel.reloadWithFilters(filters: filterViewModel)
            }
        }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            Text(category == .all ? "Movies" : category.displayName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            // Filter Count Badge
            if filterViewModel.hasActiveFilters {
                Text("\(filterViewModel.activeFilterCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.Seerr.indigo)
                    .clipShape(Circle())
            }

            // Filter Button
            Button {
                showFilterSheet = true
            } label: {
                Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(10)
            }
            .buttonStyle(.card)
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 24)
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
                    await viewModel.loadMovies(filters: filterViewModel)
                }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding()
                    .background(Color.Seerr.indigo)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.borderless)
        }
        .padding()
    }

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Smart grid with improved focus navigation
                SmartMediaGrid(
                    items: viewModel.movies,
                    columnsPerRow: 6,
                    spacing: 50,
                    horizontalPadding: 48
                ) { mediaResult in
                    // Load more when approaching the end
                    if mediaResult.id == viewModel.movies.last?.id {
                        Task {
                            await viewModel.loadMoreMovies(filters: filterViewModel)
                        }
                    }
                }
                .padding(.top, 30)  // Prevent top row from being clipped when focused

                // Loading indicator at bottom
                if viewModel.isLoadingMore {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                        .padding(.top, 40)
                        .padding(.bottom, 60)
                }
            }
        }
    }
}

// MARK: - Movie Category

enum MovieCategory: Hashable {
    case all
    case available
    case popular
    case upcoming
    case topRated

    var displayName: String {
        switch self {
        case .all: return "All Movies"
        case .available: return "Available Movies"
        case .popular: return "Popular Movies"
        case .upcoming: return "Upcoming Movies"
        case .topRated: return "Top Rated Movies"
        }
    }
}

// MARK: - ViewModel

@MainActor
class AllMoviesViewModel: ObservableObject {
    @Published var movies: [MediaResult] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?

    private var currentPage = 0
    private var totalPages = 1
    private var hasLoadedInitial = false

    private let service = SeerrService.shared
    let category: MovieCategory

    init(category: MovieCategory) {
        self.category = category
    }

    /// Initial load
    func loadMovies(filters: FilterViewModel) async {
        guard !hasLoadedInitial else { return }

        isLoading = true
        errorMessage = nil
        currentPage = 0
        movies = []

        do {
            currentPage = 1
            let response = try await fetchMovies(page: currentPage, filters: filters)

            self.movies = response.results
            self.totalPages = response.totalPages
            hasLoadedInitial = true
        } catch {
            errorMessage = "Failed to load movies: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Reload with new filters
    func reloadWithFilters(filters: FilterViewModel) async {
        isLoading = true
        errorMessage = nil
        currentPage = 0
        movies = []
        hasLoadedInitial = false

        await loadMovies(filters: filters)
    }

    /// Load more for pagination
    func loadMoreMovies(filters: FilterViewModel) async {
        guard !isLoadingMore && currentPage < totalPages else { return }

        isLoadingMore = true

        do {
            let nextPage = currentPage + 1
            let response = try await fetchMovies(page: nextPage, filters: filters)

            self.movies.append(contentsOf: response.results)
            self.currentPage = nextPage
            self.totalPages = response.totalPages
        } catch {
            print("Failed to load more movies: \(error)")
        }

        isLoadingMore = false
    }

    /// Fetch movies based on category and filters
    private func fetchMovies(page: Int, filters: FilterViewModel) async throws -> PaginatedResponse<MediaResult> {
        switch category {
        case .all:
            let params = filters.buildMovieQueryParameters(page: page)
            let response: PaginatedResponse<MovieResult> = try await service.discoverMovies(
                page: params.page,
                sortBy: params.sortBy,
                genre: params.genre,
                keywords: params.keywords,
                excludeKeywords: params.excludeKeywords,
                studio: params.studio,
                primaryReleaseDateGte: params.primaryReleaseDateGte,
                primaryReleaseDateLte: params.primaryReleaseDateLte,
                language: params.language,
                watchRegion: params.watchRegion,
                watchProviders: params.watchProviders,
                withRuntimeGte: params.withRuntimeGte,
                withRuntimeLte: params.withRuntimeLte,
                voteAverageGte: params.voteAverageGte,
                voteAverageLte: params.voteAverageLte,
                voteCountGte: params.voteCountGte,
                voteCountLte: params.voteCountLte,
                certification: params.certification,
                certificationGte: params.certificationGte,
                certificationLte: params.certificationLte,
                certificationCountry: params.certificationCountry
            )
            return PaginatedResponse(
                page: response.page,
                totalPages: response.totalPages,
                totalResults: response.totalResults,
                results: response.results.map { MediaResult.movie($0) }
            )

        case .available:
            return try await service.getAvailableMedia(type: "movie", page: page, sortBy: filters.sortBy.rawValue)

        case .popular:
            return try await service.getPopularMovies(page: page)

        case .upcoming:
            return try await service.getUpcomingMovies(page: page)

        case .topRated:
            let params = filters.buildMovieQueryParameters(page: page)
            let response: PaginatedResponse<MovieResult> = try await service.discoverMovies(
                page: page,
                sortBy: "voteAverage.desc",
                genre: params.genre,
                keywords: params.keywords,
                excludeKeywords: params.excludeKeywords,
                studio: params.studio,
                primaryReleaseDateGte: params.primaryReleaseDateGte,
                primaryReleaseDateLte: params.primaryReleaseDateLte,
                language: params.language,
                watchRegion: params.watchRegion,
                watchProviders: params.watchProviders,
                withRuntimeGte: params.withRuntimeGte,
                withRuntimeLte: params.withRuntimeLte,
                voteAverageGte: params.voteAverageGte,
                voteAverageLte: params.voteAverageLte,
                voteCountGte: params.voteCountGte,
                voteCountLte: params.voteCountLte,
                certification: params.certification,
                certificationGte: params.certificationGte,
                certificationLte: params.certificationLte,
                certificationCountry: params.certificationCountry
            )
            return PaginatedResponse(
                page: response.page,
                totalPages: response.totalPages,
                totalResults: response.totalResults,
                results: response.results.map { MediaResult.movie($0) }
            )
        }
    }
}

#Preview {
    NavigationStack {
        AllMoviesView(category: .all)
            .environmentObject(ConfigManager())
    }
}
