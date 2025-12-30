//
//  MediaDetailView.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import SwiftUI
import Kingfisher

/// Media detail page (movie or TV show)
/// Dispatcher view that loads data and shows MovieDetailView or SeriesDetailView
struct MediaDetailView: View {
    let mediaResult: MediaResult

    @StateObject private var viewModel = MediaDetailViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.Seerr.background.ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            } else if let movieDetails = viewModel.movieDetails {
                MovieDetailView(movieDetails: movieDetails)
            } else if let tvDetails = viewModel.tvDetails {
                SeriesDetailView(tvDetails: tvDetails)
            }
        }
        .task {
            await viewModel.loadDetails(from: mediaResult)
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2.0)
            Text("Loading...")
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red.opacity(0.7))

            Text("Error")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(message)
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.loadDetails(from: mediaResult)
                }
            } label: {
                Text("Retry")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .buttonStyle(.borderless)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    MediaDetailView(mediaResult: .movie(MovieResult(
        id: 550,
        adult: false,
        backdropPath: nil,
        posterPath: nil,
        genreIds: [18, 53],
        originalLanguage: "en",
        originalTitle: "Fight Club",
        overview: "A ticking-time-bomb insomniac and a slippery soap salesman channel primal male aggression into a shocking new form of therapy.",
        popularity: 100,
        releaseDate: "1999-10-15",
        firstAirDate: nil,
        title: "Fight Club",
        name: nil,
        originCountry: nil,
        originalName: nil,
        video: false,
        voteAverage: 8.4,
        voteCount: 20000,
        mediaType: "movie",
        mediaInfo: nil
    )))
}
