//
//  RequestsMediaRow.swift
//  Molyseerr
//
//  Created by Claude on 02/01/2026.
//

import SwiftUI
import Kingfisher

/// Horizontal scrollable row of request cards
/// Shows requests with landscape cards including user info and status badges
struct RequestsMediaRow: View {
    let title: String
    let requests: [MediaRequest]

    // MARK: - Constants
    private let cardSpacing: CGFloat = 40
    private let horizontalPadding: CGFloat = 60
    private let verticalPadding: CGFloat = 40

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section title
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.leading, horizontalPadding)

            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: cardSpacing) {
                    ForEach(requests) { request in
                        RequestCardLandscape(request: request)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
            }
            .scrollClipDisabled()
        }
    }
}

/// Landscape request card for profile view
/// Similar to RequestDiscoverCard but optimized for profile display
struct RequestCardLandscape: View {
    let request: MediaRequest

    @FocusState private var isFocused: Bool

    // MARK: - Constants
    private let cardWidth: CGFloat = 450
    private let cardHeight: CGFloat = 253
    private let focusScale: CGFloat = 1.05
    private let cornerRadius: CGFloat = 12

    var body: some View {
        if let mediaResult = createMediaResult(from: request) {
            NavigationLink {
                MediaDetailView(mediaResult: mediaResult)
            } label: {
                cardContent
            }
            .buttonStyle(.card)
            .focused($isFocused)
            .scaleEffect(isFocused ? focusScale : 1.0)
            .shadow(radius: isFocused ? 20 : 4, y: isFocused ? 10 : 2)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
    }

    private var cardContent: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image (backdrop or poster)
            backgroundImage

            // Gradient overlay for text readability
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(1.0),
                    Color.black.opacity(0.85),
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.4),
                    Color.clear
                ]),
                startPoint: .bottom,
                endPoint: .top
            )

            // Content overlay
            VStack(alignment: .leading, spacing: 8) {
                // Year
                if let yearText = yearDisplay {
                    Text(yearText)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                // Title
                Text(request.media?.title ?? "Unknown Title")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)

                // User info with avatar
                if let requestedBy = request.requestedBy {
                    HStack(spacing: 8) {
                        avatarView(for: requestedBy)
                        Text(requestedBy.displayName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }

                // Status badge
                RequestStatusBadge(status: request.status)
            }
            .padding(16)
        }
        .frame(width: cardWidth, height: cardHeight)
        .cornerRadius(cornerRadius)
    }

    // MARK: - Subviews

    private var backgroundImage: some View {
        Group {
            if let media = request.media {
                // Try backdrop first, fallback to poster
                let imageURL = backdropURL(for: media) ?? posterURL(for: media)

                if let imageURL = imageURL {
                    KFImage(imageURL)
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: cardWidth, height: cardHeight)
                        .clipped()
                } else {
                    placeholderView
                }
            } else {
                placeholderView
            }
        }
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: cardWidth, height: cardHeight)
            .overlay(
                Image(systemName: request.media?.mediaType == .movie ? "film" : "tv")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.3))
            )
    }

    @ViewBuilder
    private func avatarView(for user: User) -> some View {
        if let avatar = user.avatar, !avatar.isEmpty {
            let serverURL = UserDefaults.standard.string(forKey: "seerr_base_url") ?? ""
            let fullAvatarURL = "\(serverURL)\(avatar)"
            let avatarURL = URL(string: fullAvatarURL)

            let kfImage = KFImage(avatarURL)
                .placeholder {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(String(user.displayName.prefix(1)))
                                .font(.caption)
                                .foregroundColor(.white)
                        )
                }

            if let sessionCookie = UserDefaults.standard.string(forKey: "sessionCookie") {
                let modifier = AnyModifier { request in
                    var r = request
                    r.setValue(sessionCookie, forHTTPHeaderField: "Cookie")
                    return r
                }
                kfImage
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 28, height: 28)))
                    .requestModifier(modifier)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            } else {
                kfImage
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 28, height: 28)))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            }
        } else {
            Circle()
                .fill(Color.blue)
                .frame(width: 28, height: 28)
                .overlay(
                    Text(String(user.displayName.prefix(1)))
                        .font(.caption)
                        .foregroundColor(.white)
                )
        }
    }

    // MARK: - Helpers

    private var yearDisplay: String? {
        guard let media = request.media else { return nil }
        let releaseDateString = media.releaseDate ?? media.firstAirDate
        guard let dateString = releaseDateString,
              let date = ISO8601DateFormatter().date(from: dateString),
              let year = Calendar.current.dateComponents([.year], from: date).year else {
            return nil
        }
        return String(year)
    }

    private func backdropURL(for media: MediaInfo) -> URL? {
        guard let backdropPath = media.backdropPath else { return nil }
        return TMDBImageHelper.backdropURL(path: backdropPath)
    }

    private func posterURL(for media: MediaInfo) -> URL? {
        guard let posterPath = media.posterPath else { return nil }
        return TMDBImageHelper.posterURL(path: posterPath)
    }

    private func createMediaResult(from request: MediaRequest) -> MediaResult? {
        guard let media = request.media else { return nil }

        if media.mediaType == .movie || media.mediaType == nil {
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
                name: media.title ?? "",
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
