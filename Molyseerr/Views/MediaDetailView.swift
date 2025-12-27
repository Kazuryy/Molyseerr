//
//  MediaDetailView.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import SwiftUI
import Kingfisher

/// Media detail page (movie or TV show)
/// Apple TV+ inspired design with full backdrop and content overlay
struct MediaDetailView: View {
    let mediaResult: MediaResult

    @StateObject private var viewModel = MediaDetailViewModel()
    @Environment(\.dismiss) private var dismiss

    // MARK: - Constants
    private let backdropHeight: CGFloat = 800
    private let contentTopPadding: CGFloat = 150
    private let horizontalPadding: CGFloat = 90

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            } else {
                detailContent
            }
        }
        .task {
            await viewModel.loadDetails(from: mediaResult)
        }
    }

    // MARK: - Subviews

    private var detailContent: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                // Backdrop image
                backdropView
                    .frame(height: backdropHeight)

                // Content overlay
                VStack(alignment: .leading, spacing: 20) {
                    Spacer()
                        .frame(height: contentTopPadding)

                    // Poster + Info section
                    HStack(alignment: .top, spacing: 30) {
                        // Poster
                        posterView
                            .frame(width: 240, height: 360)

                        // Info
                        VStack(alignment: .leading, spacing: 16) {
                            // Title - Using tvOS Large Title spec (48-60pt)
                            Text(viewModel.title)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                                .lineSpacing(-2)

                            // Metadata row (year, runtime, rating)
                            metadataRow

                            // Genres
                            genresRow

                            // Overview - Using tvOS Body spec (26-28pt)
                            if let overview = viewModel.overview {
                                Text(overview)
                                    .font(.system(size: 26))
                                    .foregroundColor(Color(white: 235/255, opacity: 0.6))
                                    .lineSpacing(2)
                                    .lineLimit(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            // Action buttons
                            actionButtons
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, horizontalPadding)

                    // Cast section
                    if !viewModel.topCast.isEmpty {
                        castSection
                            .padding(.top, 40)
                    }

                    Spacer()
                        .frame(height: 100)
                }
            }
        }
    }

    private var backdropView: some View {
        ZStack(alignment: .bottom) {
            // Backdrop image
            if let backdropURL = TMDBImageHelper.backdropURL(path: viewModel.backdropPath) {
                KFImage(backdropURL)
                    .placeholder {
                        Color(red: 0.1, green: 0.15, blue: 0.3)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: backdropHeight)
                    .clipped()
            } else {
                Color(red: 0.1, green: 0.15, blue: 0.3)
            }

            // Gradient overlay (dark at bottom)
            LinearGradient(
                gradient: Gradient(colors: [
                    .clear,
                    .black.opacity(0.3),
                    .black.opacity(0.7),
                    .black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var posterView: some View {
        Group {
            if let posterURL = TMDBImageHelper.posterURL(path: viewModel.posterPath) {
                KFImage(posterURL)
                    .placeholder {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(ProgressView().scaleEffect(1.5))
                    }
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fit)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: viewModel.mediaType == .movie ? "film" : "tv")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.3))
                    )
            }
        }
    }

    private var metadataRow: some View {
        HStack(spacing: 12) {
            // Year - Using tvOS Callout spec (24-26pt)
            if let year = viewModel.year {
                Text(year)
                    .font(.system(size: 24))
                    .foregroundColor(Color(white: 235/255, opacity: 0.6))
            }

            // Runtime
            if let runtime = viewModel.runtime {
                Circle()
                    .fill(Color(white: 1, opacity: 0.5))
                    .frame(width: 4, height: 4)

                Text(runtime)
                    .font(.system(size: 24))
                    .foregroundColor(Color(white: 235/255, opacity: 0.6))
            }

            // Rating
            if let rating = viewModel.voteAverage {
                Circle()
                    .fill(Color(white: 1, opacity: 0.5))
                    .frame(width: 4, height: 4)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.yellow)

                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 24))
                        .foregroundColor(Color(white: 235/255, opacity: 0.6))
                }
            }

            // Status badge
            statusBadge
        }
    }

    private var statusBadge: some View {
        Group {
            if viewModel.isAvailable {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                    Text("Available")
                        .font(.system(size: 22, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.green.opacity(0.2)))
            } else if viewModel.hasPendingRequest {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                    Text("Pending")
                        .font(.system(size: 22, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.orange.opacity(0.2)))
            }
        }
    }

    private var genresRow: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.genres.prefix(4)) { genre in
                Text(genre.name)
                    .font(.system(size: 24))
                    .foregroundColor(Color(white: 235/255, opacity: 0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(Color(white: 1, opacity: 0.3), lineWidth: 1)
                    )
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Request button - Using tvOS Headline spec (28-30pt)
            if viewModel.canRequest {
                Button {
                    // TODO: Handle request action
                    print("Request tapped")
                } label: {
                    Label("Request", systemImage: "plus.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            // Watchlist button (placeholder)
            Button {
                // TODO: Handle watchlist action
                print("Watchlist tapped")
            } label: {
                Label("My List", systemImage: "plus")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color(white: 1, opacity: 0.2))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    private var castSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Cast")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.leading, horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    ForEach(viewModel.topCast) { cast in
                        CastCardView(cast: cast)
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
    }

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
            .buttonStyle(.plain)
        }
        .padding()
    }
}

// MARK: - Cast Card

struct CastCardView: View {
    let cast: Cast

    var body: some View {
        VStack(spacing: 12) {
            // Profile image
            if let profileURL = TMDBImageHelper.imageURL(path: cast.profilePath, size: .posterMedium) {
                KFImage(profileURL)
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.3))
                            )
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 150)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                    )
            }

            // Name
            Text(cast.name)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 150)

            // Character
            if let character = cast.character {
                Text(character)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                    .frame(width: 150)
            }
        }
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
