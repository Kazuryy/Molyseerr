//
//  ContentView.swift
//  Molyseerr
//
//  Created by Ronan Jacques on 23/12/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TrendingViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.trendingItems.isEmpty {
                    // Initial loading state
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    // Error state
                    errorView(message: errorMessage)
                } else if viewModel.trendingItems.isEmpty {
                    // Empty state
                    emptyView
                } else {
                    // Content loaded successfully
                    trendingList
                }
            }
            .navigationTitle("Trending")
        }
        .task {
            // Load trending content when view appears
            await viewModel.fetchTrending()
        }
    }

    // MARK: - Subviews

    /// Loading indicator view
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading trending content...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    /// Error state view
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Error")
                .font(.title)
                .fontWeight(.bold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task {
                    await viewModel.refresh()
                }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    /// Empty state view
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "film")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Trending Content")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Check back later for trending movies and TV shows.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    /// List of trending items
    private var trendingList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.trendingItems, id: \.id) { item in
                    TrendingItemRow(item: item)
                }

                // Load more indicator
                if viewModel.hasMorePages {
                    ProgressView()
                        .padding()
                        .task {
                            await viewModel.loadNextPage()
                        }
                }
            }
            .padding()
        }
    }
}

// MARK: - Trending Item Row

/// Individual row for a trending item
struct TrendingItemRow: View {
    let item: MediaResult

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Placeholder for poster image (will add Kingfisher in Phase 5)
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 150)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: item.mediaType == .movie ? "film" : "tv")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.5))
                )

            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(item.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                // Media type badge
                HStack {
                    Text(item.mediaType == .movie ? "Movie" : "TV Show")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.mediaType == .movie ? Color.blue : Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(4)

                    Spacer()
                }

                // Overview
                if let overview = item.overview {
                    Text(overview)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }

                Spacer()
            }

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .focusable() // tvOS Focus Engine support
    }
}

#Preview {
    ContentView()
}
