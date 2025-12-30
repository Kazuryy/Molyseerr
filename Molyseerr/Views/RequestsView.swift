//
//  RequestsView.swift
//  Molyseerr
//
//  Created by Claude on 28/12/2025.
//

import SwiftUI

/// Main requests view showing all user requests
struct RequestsView: View {
    // MARK: - State
    @StateObject private var viewModel = RequestsViewModel()
    @State private var toast: ToastConfig?
    @FocusState private var focusedFilter: RequestFilter?
    @FocusState private var focusedRequest: Int?

    // MARK: - Body
    var body: some View {
        contentView
            .background(Color.Seerr.background)
            .navigationBarHidden(true)
            .toast($toast)
    }

    // MARK: - Content View
    private var contentView: some View {
        ZStack {
            if viewModel.isLoading && viewModel.requests.isEmpty {
                // Loading state - aligned to top
                VStack {
                    ProgressView("Loading requests...")
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .padding(.top, 40)
                    Spacer()
                }
            } else if viewModel.requests.isEmpty {
                // Empty state
                emptyState
            } else {
                // Requests list
                requestsList
            }

            // Error overlay
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding()
                }
            }
        }
        .task {
            await viewModel.fetchRequests(refresh: true)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Text("Requests")
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 24)
    }

    // MARK: - Requests List
    private var requestsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                header

                // Filter Bar
                FilterBar(
                    selectedFilter: $viewModel.selectedFilter,
                    focusedFilter: $focusedFilter,
                    onFilterSelected: { filter in
                        Task {
                            await viewModel.applyFilter(filter)
                        }
                    }
                )

                // Requests
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.requests, id: \.id) { request in
                        requestRow(for: request)
                    }
                }
                .padding(.horizontal, 48)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
        }
    }

    @ViewBuilder
    private func requestRow(for request: MediaRequest) -> some View {
        if let mediaResult = createMediaResult(from: request) {
            NavigationLink {
                MediaDetailView(mediaResult: mediaResult)
            } label: {
                requestCard(for: request)
            }
            .buttonStyle(.borderless)
            .focused($focusedRequest, equals: request.id)

            // Load more trigger
            if request.id == viewModel.requests.last?.id && viewModel.hasMorePages {
                loadMoreView
            }
        }
    }

    private func requestCard(for request: MediaRequest) -> some View {
        RequestCardView(
            request: request,
            title: viewModel.getMediaTitle(for: request),
            posterPath: viewModel.getMediaPoster(for: request),
            isFocused: focusedRequest == request.id,
            onCancel: cancelClosure(for: request)
        )
    }

    private func cancelClosure(for request: MediaRequest) -> (() -> Void)? {
        guard request.status == .pending else { return nil }
        return {
            Task {
                await cancelRequest(request)
            }
        }
    }

    private var loadMoreView: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(.white)
            .padding()
            .task {
                await viewModel.loadMore()
            }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack {
            VStack(spacing: 16) {
                Image(systemName: "tray")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)

                Text("No \(viewModel.selectedFilter.displayName.lowercased()) requests")
                    .font(.title2)
                    .foregroundColor(.gray)

                Text("Requests you make will appear here")
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.7))
            }
            .padding(.top, 40)

            Spacer()
        }
    }

    // MARK: - Actions
    private func cancelRequest(_ request: MediaRequest) async {
        let success = await viewModel.cancelRequest(id: request.id)

        if success {
            toast = .success("Request cancelled")
        } else {
            toast = .error("Failed to cancel request")
        }
    }

    // MARK: - Helper
    private func createMediaResult(from request: MediaRequest) -> MediaResult? {
        guard let media = request.media else { return nil }

        if media.mediaType == .movie || media.mediaType == nil {  // Default to movie if nil
            let movieResult = MovieResult(
                id: media.tmdbId,
                adult: nil,
                backdropPath: media.backdropPath,
                posterPath: media.posterPath,
                genreIds: nil,
                originalLanguage: media.originalLanguage,
                originalTitle: media.originalTitle,
                overview: media.overview,
                popularity: media.popularity,
                releaseDate: media.releaseDate,
                firstAirDate: nil,
                title: media.title,
                name: nil,
                originCountry: nil,
                originalName: nil,
                video: nil,
                voteAverage: media.voteAverage,
                voteCount: media.voteCount,
                mediaType: "movie",
                mediaInfo: media
            )
            return .movie(movieResult)
        } else {
            let tvResult = TVResult(
                id: media.tmdbId,
                backdropPath: media.backdropPath,
                posterPath: media.posterPath,
                genreIds: nil,
                originalLanguage: media.originalLanguage,
                originalName: media.originalTitle,
                overview: media.overview,
                popularity: media.popularity,
                firstAirDate: media.firstAirDate,
                name: media.title ?? "Unknown",
                voteAverage: media.voteAverage,
                voteCount: media.voteCount,
                originCountry: media.originCountry,
                mediaType: "tv",
                mediaInfo: media
            )
            return .tv(tvResult)
        }
    }
}
