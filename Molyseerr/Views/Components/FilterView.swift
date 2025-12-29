//
//  FilterView.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI

/// Filter modal view for Movies and Series discovery
/// Provides comprehensive filtering options adapted for tvOS interaction
struct FilterView: View {
    @ObservedObject var filterViewModel: FilterViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 40) {
                        // Sort Section
                        sortSection

                        // Genre Section
                        genreSection

                        // Runtime Section
                        runtimeSection

                        // Rating Section
                        ratingSection

                        // Vote Count Section
                        voteCountSection

                        // Media-specific sections
                        if filterViewModel.mediaType == FilterMediaType.tv {
                            // Series Status Section
                            seriesStatusSection
                        }

                        // Action Buttons
                        actionButtonsSection
                    }
                    .padding(48)
                }
            }
            .navigationTitle("Filters")
        }
    }

    // MARK: - Sort Section

    private var sortSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sort By")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    sortOptionButton(option)
                }
            }
        }
    }

    private func sortOptionButton(_ option: SortOption) -> some View {
        Button {
            filterViewModel.sortBy = option
        } label: {
            HStack {
                Text(option.displayName)
                    .font(.body)
                    .foregroundColor(filterViewModel.sortBy == option ? .black : .white)

                Spacer()

                if filterViewModel.sortBy == option {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.black)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(filterViewModel.sortBy == option ? Color.Seerr.purple : Color.gray.opacity(0.3))
            .cornerRadius(10)
        }
        .buttonStyle(.card)
    }

    // MARK: - Genre Section

    private var genreSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Genres")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            if filterViewModel.availableGenres.isEmpty {
                ProgressView()
                    .tint(.white)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(filterViewModel.availableGenres, id: \.id) { genre in
                        genreButton(genre)
                    }
                }
            }
        }
    }

    private func genreButton(_ genre: Genre) -> some View {
        let isSelected = filterViewModel.selectedGenres.contains(genre.id)

        return Button {
            if isSelected {
                filterViewModel.selectedGenres.remove(genre.id)
            } else {
                filterViewModel.selectedGenres.insert(genre.id)
            }
        } label: {
            HStack {
                Text(genre.name)
                    .font(.body)
                    .foregroundColor(isSelected ? .black : .white)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.black)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.Seerr.purple : Color.gray.opacity(0.3))
            .cornerRadius(10)
        }
        .buttonStyle(.card)
    }

    // MARK: - Runtime Section

    private var runtimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Runtime")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                Toggle("", isOn: $filterViewModel.isRuntimeFilterActive)
                    .labelsHidden()
            }

            if filterViewModel.isRuntimeFilterActive {
                VStack(spacing: 20) {
                    // Min Runtime
                    HStack {
                        Text("Minimum: \(filterViewModel.runtimeMin) min")
                            .font(.body)
                            .foregroundColor(.secondary)

                        Spacer()

                        HStack(spacing: 10) {
                            Button {
                                if filterViewModel.runtimeMin > 0 {
                                    filterViewModel.runtimeMin = max(0, filterViewModel.runtimeMin - 10)
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)

                            Button {
                                if filterViewModel.runtimeMin < 400 {
                                    filterViewModel.runtimeMin = min(400, filterViewModel.runtimeMin + 10)
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Max Runtime
                    HStack {
                        Text("Maximum: \(filterViewModel.runtimeMax) min")
                            .font(.body)
                            .foregroundColor(.secondary)

                        Spacer()

                        HStack(spacing: 10) {
                            Button {
                                if filterViewModel.runtimeMax > 0 {
                                    filterViewModel.runtimeMax = max(0, filterViewModel.runtimeMax - 10)
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)

                            Button {
                                if filterViewModel.runtimeMax < 400 {
                                    filterViewModel.runtimeMax = min(400, filterViewModel.runtimeMax + 10)
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Rating Section

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TMDB Rating")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                Toggle("", isOn: $filterViewModel.isRatingFilterActive)
                    .labelsHidden()
            }

            if filterViewModel.isRatingFilterActive {
                VStack(spacing: 20) {
                    // Min Rating
                    HStack {
                        Text("Minimum: \(String(format: "%.1f", filterViewModel.ratingMin))")
                            .font(.body)
                            .foregroundColor(.secondary)

                        Spacer()

                        HStack(spacing: 10) {
                            Button {
                                if filterViewModel.ratingMin > 0 {
                                    filterViewModel.ratingMin = max(0, filterViewModel.ratingMin - 0.5)
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)

                            Button {
                                if filterViewModel.ratingMin < 10 {
                                    filterViewModel.ratingMin = min(10, filterViewModel.ratingMin + 0.5)
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Max Rating
                    HStack {
                        Text("Maximum: \(String(format: "%.1f", filterViewModel.ratingMax))")
                            .font(.body)
                            .foregroundColor(.secondary)

                        Spacer()

                        HStack(spacing: 10) {
                            Button {
                                if filterViewModel.ratingMax > 0 {
                                    filterViewModel.ratingMax = max(0, filterViewModel.ratingMax - 0.5)
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)

                            Button {
                                if filterViewModel.ratingMax < 10 {
                                    filterViewModel.ratingMax = min(10, filterViewModel.ratingMax + 0.5)
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Vote Count Section

    private var voteCountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Vote Count")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                Toggle("", isOn: $filterViewModel.isVoteCountFilterActive)
                    .labelsHidden()
            }

            if filterViewModel.isVoteCountFilterActive {
                VStack(spacing: 20) {
                    // Min Vote Count
                    HStack {
                        Text("Minimum: \(filterViewModel.voteCountMin)")
                            .font(.body)
                            .foregroundColor(.secondary)

                        Spacer()

                        HStack(spacing: 10) {
                            Button {
                                if filterViewModel.voteCountMin > 0 {
                                    filterViewModel.voteCountMin = max(0, filterViewModel.voteCountMin - 50)
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)

                            Button {
                                if filterViewModel.voteCountMin < 1000 {
                                    filterViewModel.voteCountMin = min(1000, filterViewModel.voteCountMin + 50)
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Max Vote Count
                    HStack {
                        Text("Maximum: \(filterViewModel.voteCountMax)")
                            .font(.body)
                            .foregroundColor(.secondary)

                        Spacer()

                        HStack(spacing: 10) {
                            Button {
                                if filterViewModel.voteCountMax > 0 {
                                    filterViewModel.voteCountMax = max(0, filterViewModel.voteCountMax - 50)
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)

                            Button {
                                if filterViewModel.voteCountMax < 1000 {
                                    filterViewModel.voteCountMax = min(1000, filterViewModel.voteCountMax + 50)
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Series Status Section

    private var seriesStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Series Status")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ForEach(SeriesStatus.allCases, id: \.self) { status in
                    seriesStatusButton(status)
                }
            }
        }
    }

    private func seriesStatusButton(_ status: SeriesStatus) -> some View {
        let isSelected = filterViewModel.selectedStatuses.contains(status)

        return Button {
            if isSelected {
                filterViewModel.selectedStatuses.remove(status)
            } else {
                filterViewModel.selectedStatuses.insert(status)
            }
        } label: {
            HStack {
                Text(status.displayName)
                    .font(.body)
                    .foregroundColor(isSelected ? .black : .white)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.black)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.Seerr.purple : Color.gray.opacity(0.3))
            .cornerRadius(10)
        }
        .buttonStyle(.card)
    }

    // MARK: - Action Buttons

    private var actionButtonsSection: some View {
        HStack(spacing: 30) {
            // Clear Filters Button
            Button {
                filterViewModel.clearFilters()
            } label: {
                Label("Clear Filters", systemImage: "xmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(10)
            }
            .buttonStyle(.card)
            .disabled(!filterViewModel.hasActiveFilters)
            .opacity(filterViewModel.hasActiveFilters ? 1.0 : 0.5)

            // Apply Filters Button
            Button {
                dismiss()
            } label: {
                Label("Apply Filters", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.Seerr.purple)
                    .cornerRadius(10)
            }
            .buttonStyle(.card)
        }
    }
}

#Preview {
    FilterView(filterViewModel: FilterViewModel(mediaType: FilterMediaType.movie))
}
