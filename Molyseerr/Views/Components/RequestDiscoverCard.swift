import SwiftUI
import Kingfisher

struct RequestDiscoverCard: View {
    let request: MediaRequest
    let title: String?
    let posterPath: String?
    let backdropPath: String?

    @Environment(\.isFocused) private var isFocused

    // Match TodayReleaseCard dimensions
    private let cardWidth: CGFloat = 450
    private let cardHeight: CGFloat = 253
    private let focusScale: CGFloat = 1.08
    private let cornerRadius: CGFloat = 12

    var body: some View {
        if let mediaResult = createMediaResult(from: request) {
            NavigationLink {
                MediaDetailView(mediaResult: mediaResult)
            } label: {
                cardContent
            }
            .buttonStyle(.card)
            .scaleEffect(isFocused ? focusScale : 1.0)
            .shadow(radius: isFocused ? 20 : 4, y: isFocused ? 10 : 2)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
    }

    private var cardContent: some View {
        ZStack(alignment: .bottomLeading) {
            // Background with backdrop image (or poster as fallback)
            if let media = request.media {
                // Use the fetched backdropPath from TMDB API
                let fetchedBackdropPath = backdropPath
                let fallbackPosterPath = posterPath

                let imageURL: URL? = {
                    // Try backdrop first (from TMDB API fetch)
                    if let backdropPath = fetchedBackdropPath, !backdropPath.isEmpty {
                        if backdropPath.hasPrefix("http://") || backdropPath.hasPrefix("https://") {
                            return URL(string: backdropPath)
                        } else {
                            return TMDBImageHelper.imageURL(path: backdropPath, size: .backdropMedium)
                        }
                    }
                    // Fallback to poster
                    else if let posterPath = fallbackPosterPath, !posterPath.isEmpty {
                        if posterPath.hasPrefix("http://") || posterPath.hasPrefix("https://") {
                            return URL(string: posterPath)
                        } else {
                            return TMDBImageHelper.posterURL(path: posterPath)
                        }
                    }
                    return nil
                }()

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
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: cardWidth, height: cardHeight)
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: cardWidth, height: cardHeight)
            }

            // Gradient overlay for text readability (darker for better contrast)
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

            // Bottom content
            VStack(alignment: .leading, spacing: 6) {
                // Year
                if let media = request.media {
                    let releaseDateString = media.releaseDate ?? media.firstAirDate
                    if let dateString = releaseDateString,
                       let date = ISO8601DateFormatter().date(from: dateString),
                       let year = Calendar.current.dateComponents([.year], from: date).year {
                        Text(String(year))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                // Title
                Text(title ?? "Unknown Title")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)

                // User info with avatar
                if let requestedBy = request.requestedBy {
                    HStack(spacing: 8) {
                        // User avatar
                        avatarView(for: requestedBy)

                        // Username
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

    @ViewBuilder
    private func avatarView(for user: User) -> some View {
        if let avatar = user.avatar, !avatar.isEmpty {
            // Avatar is a path like "/avatarproxy/xxx?v=xxx" - build full URL with server
            let serverURL = UserDefaults.standard.string(forKey: "seerr_base_url") ?? ""
            let fullAvatarURL = "\(serverURL)\(avatar)"
            let avatarURL = URL(string: fullAvatarURL)

            // Build KFImage with authentication if needed
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

            // Apply authentication headers if we have a session cookie
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
            // Fallback to initials
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

    private func createMediaResult(from request: MediaRequest) -> MediaResult? {
        guard let media = request.media else { return nil }

        if media.mediaType == .movie || media.mediaType == nil {  // Default to movie if nil
            let movieResult = MovieResult(
                id: media.tmdbId,
                adult: nil,
                backdropPath: media.backdropPath,
                posterPath: posterPath,
                genreIds: nil,
                originalLanguage: media.originalLanguage,
                originalTitle: media.originalTitle,
                overview: media.overview,
                popularity: media.popularity,
                releaseDate: media.releaseDate,
                firstAirDate: nil,
                title: title,
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
                posterPath: posterPath,
                genreIds: nil,
                originalLanguage: media.originalLanguage,
                originalName: media.originalTitle,
                overview: media.overview,
                popularity: media.popularity,
                firstAirDate: media.firstAirDate,
                name: title ?? "",
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

// Status badge component matching webapp colors for discover cards
struct RequestStatusBadge: View {
    let status: RequestStatus

    var statusColor: Color {
        switch status {
        case .pending:
            return Color(hex: "EAB308") // Yellow
        case .approved:
            return Color(hex: "3B82F6") // Blue
        case .declined, .failed:
            return Color(hex: "EF4444") // Red
        case .completed:
            return Color(hex: "22C55E") // Green
        }
    }

    var statusText: String {
        switch status {
        case .pending:
            return "Pending"
        case .approved:
            return "Approved"
        case .declined:
            return "Declined"
        case .failed:
            return "Failed"
        case .completed:
            return "Available"
        }
    }

    var body: some View {
        Text(statusText)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(6)
    }
}

