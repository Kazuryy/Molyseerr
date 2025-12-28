//
//  RequestSheet.swift
//  Molyseerr
//
//  Created by Claude on 28/12/2025.
//

import SwiftUI
import Kingfisher

/// Request creation sheet for movies and TV shows
struct RequestSheet: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @StateObject private var viewModel: CreateRequestViewModel
    @State private var toast: ToastConfig?
    @FocusState private var focusedField: Field?

    // Callback when request is created
    let onRequestCreated: (() async -> Void)?

    // Media details for display
    let title: String
    let year: String?
    let posterPath: String?
    let mediaType: MediaType

    enum Field: Hashable {
        case is4kToggle
        case seasonToggle(Int)
        case allSeasonsToggle
        case submitButton
        case cancelButton
    }

    // MARK: - Initialization
    init(
        mediaType: MediaType,
        mediaId: Int,
        title: String,
        year: String?,
        posterPath: String?,
        seasons: [Season] = [],
        onRequestCreated: (() async -> Void)? = nil
    ) {
        self.mediaType = mediaType
        self.title = title
        self.year = year
        self.posterPath = posterPath
        self.onRequestCreated = onRequestCreated

        _viewModel = StateObject(wrappedValue: CreateRequestViewModel(
            mediaType: mediaType,
            mediaId: mediaId,
            seasons: seasons
        ))
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            // Content
            ScrollView {
                VStack(spacing: 32) {
                    // Media Info
                    mediaInfo

                    // Season Selection (TV only)
                    if mediaType == .tv && !viewModel.allSeasons.isEmpty {
                        seasonSelection
                    }

                    // 4K Option
                    is4kToggle

                    // Action Buttons
                    actionButtons
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 32)
            }
        }
        .frame(width: 900, height: 700)
        .background(Color.black.opacity(0.95))
        .cornerRadius(16)
        .toast($toast)
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Text(mediaType == .movie ? "Request Movie" : "Request TV Show")
                .font(.title)
                .fontWeight(.bold)

            Spacer()
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 24)
        .background(Color.black.opacity(0.3))
    }

    // MARK: - Media Info
    private var mediaInfo: some View {
        HStack(spacing: 24) {
            // Poster
            if let posterPath = posterPath {
                let posterURL = URL(string: "https://image.tmdb.org/t/p/w300\(posterPath)")
                KFImage(posterURL)
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fit)
                    .frame(width: 120)
                    .cornerRadius(8)
            }

            // Title & Info
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)

                if let year = year {
                    Text(year)
                        .font(.headline)
                        .foregroundColor(.gray)
                }

                if mediaType == .tv, !viewModel.allSeasons.isEmpty {
                    Text("\(viewModel.allSeasons.count) Seasons")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Spacer()
        }
    }

    // MARK: - Season Selection
    private var seasonSelection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Seasons:")
                .font(.headline)
                .fontWeight(.semibold)

            // All Seasons Toggle
            Button {
                viewModel.toggleAllSeasons()
            } label: {
                HStack {
                    Image(systemName: viewModel.areAllSeasonsSelected ? "checkmark.square.fill" : "square")
                        .font(.title3)
                    Text("All Seasons")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(viewModel.areAllSeasonsSelected ? Color.Seerr.primary : Color.white.opacity(0.2))
                )
            }
            .buttonStyle(.plain)
            .focused($focusedField, equals: .allSeasonsToggle)

            // Individual Season Toggles
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 180), spacing: 16)
            ], spacing: 16) {
                ForEach(viewModel.allSeasons, id: \.seasonNumber) { season in
                    let seasonNumber = season.seasonNumber
                    let isSelected = viewModel.selectedSeasons.contains(seasonNumber)

                    Button {
                        viewModel.toggleSeason(seasonNumber)
                    } label: {
                        HStack {
                            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                .font(.body)
                            Text(season.name ?? "Season \(seasonNumber)")
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? Color.Seerr.primary : Color.white.opacity(0.2))
                        )
                    }
                    .buttonStyle(.plain)
                    .focused($focusedField, equals: .seasonToggle(seasonNumber))
                }
            }

            if viewModel.selectedSeasons.isEmpty {
                Text("Please select at least one season")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - 4K Toggle
    private var is4kToggle: some View {
        Button {
            viewModel.is4K.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: viewModel.is4K ? "checkmark.square.fill" : "square")
                    .font(.title3)
                Image(systemName: "4k.tv")
                    .font(.title3)
                Text("Request in 4K")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.is4K ? Color.Seerr.primary : Color.white.opacity(0.2))
            )
        }
        .buttonStyle(.plain)
        .focused($focusedField, equals: .is4kToggle)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 24) {
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.primary)
            .buttonBorderShape(.roundedRectangle(radius: 8))
            .focused($focusedField, equals: .cancelButton)

            Button {
                Task {
                    await submitRequest()
                }
            } label: {
                if viewModel.isSubmitting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.black)
                } else {
                    Text("Request")
                }
            }
            .buttonStyle(.primary)
            .buttonBorderShape(.roundedRectangle(radius: 8))
            .disabled(!viewModel.canSubmit)
            .opacity(viewModel.canSubmit ? 1.0 : 0.5)
            .focused($focusedField, equals: .submitButton)
        }
    }

    // MARK: - Actions
    private func submitRequest() async {
        let success = await viewModel.submitRequest()

        if success {
            toast = .success("Request created successfully!")
            // Wait for toast to show, then dismiss
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            await onRequestCreated?()
            dismiss()
        } else if let errorMessage = viewModel.errorMessage {
            toast = .error(errorMessage)
        }
    }
}

/// Convenience initializers for different media types
extension RequestSheet {
    /// Create RequestSheet from MovieDetails
    init(
        movieDetails: MovieDetails,
        onRequestCreated: (() async -> Void)? = nil
    ) {
        self.init(
            mediaType: .movie,
            mediaId: movieDetails.id,
            title: movieDetails.title,
            year: movieDetails.releaseYear,
            posterPath: movieDetails.posterPath,
            seasons: [],
            onRequestCreated: onRequestCreated
        )
    }

    /// Create RequestSheet from TVDetails
    init(
        tvDetails: TVDetails,
        onRequestCreated: (() async -> Void)? = nil
    ) {
        self.init(
            mediaType: .tv,
            mediaId: tvDetails.id,
            title: tvDetails.name,
            year: tvDetails.firstAirYear,
            posterPath: tvDetails.posterPath,
            seasons: tvDetails.seasons ?? [],
            onRequestCreated: onRequestCreated
        )
    }
}
