//
//  SearchView.swift
//  Molyseerr
//
//  Created by Claude on 31/12/2025.
//

import SwiftUI

/// Main search view for tvOS
/// Allows users to search for movies and TV shows
struct SearchView: View {
    // MARK: - State
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText: String = ""
    @FocusState private var isSearchFieldFocused: Bool
    @FocusState private var focusedItemId: Int?

    // MARK: - Constants
    private let gridColumns = [
        GridItem(.adaptive(minimum: 250, maximum: 250), spacing: 40)
    ]

    // MARK: - Body
    var body: some View {
        NavigationStack {
            contentView
                .background(Color.Seerr.background)
                .navigationBarHidden(true)
        }
    }

    // MARK: - Content View
    private var contentView: some View {
        ZStack {
            if viewModel.searchResults.isEmpty && viewModel.searchQuery.isEmpty {
                // Initial state - show search prompt (no search performed yet)
                initialState
            } else if viewModel.isLoading && viewModel.searchResults.isEmpty {
                // Loading state
                loadingState
            } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                // No results (search was performed but found nothing)
                emptyState
            } else {
                // Results list
                resultsList
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
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Search")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()
            }

            // Search field
            searchField
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 24)
    }

    // MARK: - Search Field
    private var searchField: some View {
        HStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundColor(.gray)

            TextField("Search for movies and TV shows...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($isSearchFieldFocused)
                .submitLabel(.search)
                .onSubmit {
                    // Trigger search when user presses search button
                    Task {
                        await viewModel.search(query: searchText)
                    }
                    isSearchFieldFocused = false
                }

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else if !searchText.isEmpty {
                // Search button
                Button {
                    Task {
                        await viewModel.search(query: searchText)
                    }
                    isSearchFieldFocused = false
                } label: {
                    Text("Search")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.Seerr.primary)
                        .cornerRadius(8)
                }
                .buttonStyle(.borderless)

                // Clear button
                Button {
                    searchText = ""
                    viewModel.clearResults()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSearchFieldFocused ? Color.white.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 2)
        )
    }

    // MARK: - Initial State
    private var initialState: some View {
        VStack {
            header

            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 100))
                    .foregroundColor(.gray.opacity(0.5))

                Text("Search for Movies and TV Shows")
                    .font(.title)
                    .foregroundColor(.white)

                Text("Start typing to find your favorite content")
                    .font(.title3)
                    .foregroundColor(.gray)

                // Tips
                VStack(alignment: .leading, spacing: 12) {
                    tipRow(icon: "number", text: "Use tmdb:12345 to search by TMDB ID")
                    tipRow(icon: "film", text: "Use imdb:tt1234567 to search by IMDB ID")
                    tipRow(icon: "calendar", text: "Use year:2024 to filter by year")
                }
                .padding(.top, 24)
            }

            Spacer()
        }
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.Seerr.primary)
                .frame(width: 24)

            Text(text)
                .font(.body)
                .foregroundColor(.gray)
        }
    }

    // MARK: - Loading State
    private var loadingState: some View {
        VStack {
            header

            VStack {
                ProgressView("Searching...")
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.2)
                    .padding(.top, 40)
                Spacer()
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack {
            header

            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)

                Text("No results found")
                    .font(.title2)
                    .foregroundColor(.gray)

                Text("Try different keywords or check your spelling")
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.7))
            }
            .padding(.top, 40)

            Spacer()
        }
    }

    // MARK: - Results List
    private var resultsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with search field
                header

                // Results count
                if !viewModel.searchResults.isEmpty {
                    HStack {
                        Text("\(viewModel.searchResults.count) results")
                            .font(.headline)
                            .foregroundColor(.gray)

                        Spacer()
                    }
                    .padding(.horizontal, 48)
                    .padding(.bottom, 16)
                }

                // Results grid
                LazyVGrid(columns: gridColumns, spacing: 40) {
                    ForEach(viewModel.searchResults, id: \.id) { result in
                        MediaCardView(item: result)
                            .id(result.id)
                            .focused($focusedItemId, equals: result.id)

                            // Load more trigger
                            .onAppear {
                                if result.id == viewModel.searchResults.last?.id && viewModel.hasMorePages {
                                    Task {
                                        await viewModel.loadMore()
                                    }
                                }
                            }
                    }
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 24)

                // Load more indicator
                if viewModel.isLoading && !viewModel.searchResults.isEmpty {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .padding()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SearchView()
        .environmentObject(ConfigManager())
}
