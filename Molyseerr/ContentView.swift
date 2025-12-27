//
//  ContentView.swift
//  Molyseerr
//
//  Created by Kazuryy on 23/12/2025.
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

    /// Apple TV+ style horizontal rows
    private var trendingList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 60) {
                // Trending row
                HorizontalMediaRow(
                    title: "Trending Now",
                    items: viewModel.trendingItems
                )

                // Load more indicator
                if viewModel.hasMorePages {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                            .task {
                                await viewModel.loadNextPage()
                            }
                        Spacer()
                    }
                    .padding(.vertical, 40)
                }
            }
            .padding(.top, 40)
        }
        .background(Color.black)
    }
}

#Preview {
    ContentView()
}
