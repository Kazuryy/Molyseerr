//
//  NetworkDetailView.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI
import Combine
import Kingfisher

/// Network detail view - displays TV shows from a specific network
/// Matches Seerr web app network detail browsing with infinite scroll
struct NetworkDetailView: View {
    let network: Company

    @StateObject private var viewModel: NetworkDetailViewModel

    // Grid layout - 6 columns for poster view (like Seerr's vertical cards)
    private let columns = [
        GridItem(.flexible(), spacing: 50),
        GridItem(.flexible(), spacing: 50),
        GridItem(.flexible(), spacing: 50),
        GridItem(.flexible(), spacing: 50),
        GridItem(.flexible(), spacing: 50),
        GridItem(.flexible(), spacing: 50)
    ]

    init(network: Company) {
        self.network = network
        _viewModel = StateObject(wrappedValue: NetworkDetailViewModel(network: network))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with network logo
                networkHeader

                // Content
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
        }
        .task {
            await viewModel.loadShows()
        }
    }

    // MARK: - Subviews

    private var networkHeader: some View {
        VStack(spacing: 0) {
            if let logoURL = network.logoURL {
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

            Text("Loading shows from \(network.name)...")
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
        .frame(maxHeight: .infinity)
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

            Text("No shows from \(network.name) are available.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
    }

    private var showGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 50) {
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
class NetworkDetailViewModel: ObservableObject {
    let network: Company

    @Published var shows: [TVResult] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?

    private var currentPage = 0
    private var totalPages = 1
    private var hasLoadedInitial = false

    init(network: Company) {
        self.network = network
    }

    func loadShows() async {
        guard !hasLoadedInitial, !isLoading else { return }

        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            let response = try await SeerrService.shared.getTVByNetwork(networkId: network.id, page: currentPage)

            // Extract TV shows from MediaResult enum
            shows = response.results.compactMap { mediaResult in
                if case .tv(let show) = mediaResult {
                    return show
                }
                return nil
            }

            totalPages = response.totalPages
            hasLoadedInitial = true

            print("✅ Loaded \(shows.count) shows for network \(network.name) (page \(currentPage)/\(totalPages))")
        } catch {
            print("❌ Failed to load shows for network \(network.name): \(error)")
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
            let response = try await SeerrService.shared.getTVByNetwork(networkId: network.id, page: currentPage)

            // Extract and append shows
            let newShows = response.results.compactMap { mediaResult -> TVResult? in
                if case .tv(let show) = mediaResult {
                    return show
                }
                return nil
            }

            shows.append(contentsOf: newShows)
            totalPages = response.totalPages

            print("✅ Loaded \(newShows.count) more shows for network \(network.name) (page \(currentPage)/\(totalPages))")
        } catch {
            print("❌ Failed to load more shows for network \(network.name): \(error)")
            // Don't show error for pagination failures, just stop loading
            currentPage -= 1 // Revert page increment
        }

        isLoadingMore = false
    }
}

#Preview {
    NavigationStack {
        NetworkDetailView(network: Company.networks[0])
    }
    .preferredColorScheme(.dark)
}
