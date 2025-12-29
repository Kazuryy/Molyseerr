//
//  AllSeriesView.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI
import Combine

/// All Series view with vertical grid and comprehensive filtering
/// Displays all TV shows with infinite scroll pagination
struct AllSeriesView: View {
    let category: SeriesCategory
    @StateObject private var viewModel: AllSeriesViewModel
    @StateObject private var filterViewModel = FilterViewModel(mediaType: FilterMediaType.tv)
    @EnvironmentObject var configManager: ConfigManager
    @State private var showFilterSheet = false

    init(category: SeriesCategory) {
        self.category = category
        _viewModel = StateObject(wrappedValue: AllSeriesViewModel(category: category))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with Filter Button
                    headerSection

                    // Content
                    Group {
                        if viewModel.isLoading && viewModel.series.isEmpty {
                            loadingView
                        } else if let errorMessage = viewModel.errorMessage, viewModel.series.isEmpty {
                            errorView(message: errorMessage)
                        } else {
                            contentView
                        }
                    }
                }
            }
            .task {
            await viewModel.loadSeries(filters: filterViewModel)
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
        .onChange(of: filterViewModel.selectedStatuses) { _, _ in
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
            Text(category == .all ? "TV Shows" : category.displayName)
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
                    .background(Color.Seerr.purple)
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
                    await viewModel.loadSeries(filters: filterViewModel)
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
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 50),
                GridItem(.flexible(), spacing: 50),
                GridItem(.flexible(), spacing: 50),
                GridItem(.flexible(), spacing: 50),
                GridItem(.flexible(), spacing: 50),
                GridItem(.flexible(), spacing: 50)
            ], spacing: 50) {
                ForEach(viewModel.series, id: \.id) { mediaResult in
                    MediaCardView(item: mediaResult)
                        .onAppear {
                            // Load more when approaching the end
                            if mediaResult.id == viewModel.series.last?.id {
                                Task {
                                    await viewModel.loadMoreSeries(filters: filterViewModel)
                                }
                            }
                        }
                }

                // Loading indicator at bottom
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

// MARK: - Series Category

enum SeriesCategory: Hashable {
    case all
    case available
    case popular
    case upcoming
    case topRated

    var displayName: String {
        switch self {
        case .all: return "All TV Shows"
        case .available: return "Available TV Shows"
        case .popular: return "Popular TV Shows"
        case .upcoming: return "Upcoming TV Shows"
        case .topRated: return "Top Rated TV Shows"
        }
    }
}

// MARK: - ViewModel

@MainActor
class AllSeriesViewModel: ObservableObject {
    @Published var series: [MediaResult] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?

    private var currentPage = 0
    private var totalPages = 1
    private var hasLoadedInitial = false

    private let service = SeerrService.shared
    let category: SeriesCategory

    init(category: SeriesCategory) {
        self.category = category
    }

    /// Initial load
    func loadSeries(filters: FilterViewModel) async {
        guard !hasLoadedInitial else { return }

        isLoading = true
        errorMessage = nil
        currentPage = 0
        series = []

        do {
            currentPage = 1
            let response = try await fetchSeries(page: currentPage, filters: filters)

            self.series = response.results
            self.totalPages = response.totalPages
            hasLoadedInitial = true
        } catch {
            errorMessage = "Failed to load TV shows: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Reload with new filters
    func reloadWithFilters(filters: FilterViewModel) async {
        isLoading = true
        errorMessage = nil
        currentPage = 0
        series = []
        hasLoadedInitial = false

        await loadSeries(filters: filters)
    }

    /// Load more for pagination
    func loadMoreSeries(filters: FilterViewModel) async {
        guard !isLoadingMore && currentPage < totalPages else { return }

        isLoadingMore = true

        do {
            let nextPage = currentPage + 1
            let response = try await fetchSeries(page: nextPage, filters: filters)

            self.series.append(contentsOf: response.results)
            self.currentPage = nextPage
            self.totalPages = response.totalPages
        } catch {
            print("Failed to load more TV shows: \(error)")
        }

        isLoadingMore = false
    }

    /// Fetch TV shows based on category and filters
    private func fetchSeries(page: Int, filters: FilterViewModel) async throws -> PaginatedResponse<MediaResult> {
        switch category {
        case .all:
            let params = filters.buildTVQueryParameters(page: page)
            let response: PaginatedResponse<TVResult> = try await service.discoverTV(
                page: params.page,
                sortBy: params.sortBy,
                genre: params.genre,
                keywords: params.keywords,
                excludeKeywords: params.excludeKeywords,
                network: params.network,
                firstAirDateGte: params.firstAirDateGte,
                firstAirDateLte: params.firstAirDateLte,
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
                certificationCountry: params.certificationCountry,
                status: params.status
            )
            return PaginatedResponse(
                page: response.page,
                totalPages: response.totalPages,
                totalResults: response.totalResults,
                results: response.results.map { MediaResult.tv($0) }
            )

        case .available:
            return try await service.getAvailableMedia(type: "tv", page: page, sortBy: filters.sortBy.rawValue)

        case .popular:
            return try await service.getPopularTV(page: page)

        case .upcoming:
            return try await service.getUpcomingTV(page: page)

        case .topRated:
            let params = filters.buildTVQueryParameters(page: page)
            let response: PaginatedResponse<TVResult> = try await service.discoverTV(
                page: page,
                sortBy: "voteAverage.desc",
                genre: params.genre,
                keywords: params.keywords,
                excludeKeywords: params.excludeKeywords,
                network: params.network,
                firstAirDateGte: params.firstAirDateGte,
                firstAirDateLte: params.firstAirDateLte,
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
                certificationCountry: params.certificationCountry,
                status: params.status
            )
            return PaginatedResponse(
                page: response.page,
                totalPages: response.totalPages,
                totalResults: response.totalResults,
                results: response.results.map { MediaResult.tv($0) }
            )
        }
    }
}

#Preview {
    NavigationStack {
        AllSeriesView(category: .all)
            .environmentObject(ConfigManager())
    }
}
