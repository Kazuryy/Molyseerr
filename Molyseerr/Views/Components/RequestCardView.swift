//
//  RequestCardView.swift
//  Molyseerr
//
//  Created by Claude on 28/12/2025.
//

import SwiftUI
import Kingfisher

/// Horizontal request card for RequestsView
struct RequestCardView: View {
    let request: MediaRequest
    let title: String
    let posterPath: String?
    let onCancel: (() -> Void)?
    let isFocused: Bool

    init(request: MediaRequest, title: String, posterPath: String? = nil, isFocused: Bool = false, onCancel: (() -> Void)? = nil) {
        self.request = request
        self.title = title
        self.posterPath = posterPath
        self.isFocused = isFocused
        self.onCancel = onCancel
    }

    var body: some View {
        cardContent
            .padding(28)
            .background(cardBackground)
            .overlay(cardBorder)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }

    private var cardContent: some View {
        HStack(spacing: 24) {
            posterView
            infoSection
            Spacer()
        }
    }

    private var posterView: some View {
        Group {
            if let posterPath = posterPath {
                let posterURL = URL(string: "https://image.tmdb.org/t/p/w300\(posterPath)")
                KFImage(posterURL)
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fit)
                    .frame(width: 180)
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 270)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "film")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    )
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            titleView
            badgesView
            userInfoView
            Spacer()
            cancelButtonView
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var titleView: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.bold)
            .lineLimit(2)
            .foregroundColor(.white)
    }

    private var badgesView: some View {
        HStack(spacing: 12) {
            MediaTypeBadgeView(mediaType: mediaType)
            StatusBadge(status: request.status)
        }
    }

    private var userInfoView: some View {
        HStack(spacing: 20) {
            avatarAndNameView
            dateView
        }
    }

    private var avatarAndNameView: some View {
        HStack(spacing: 10) {
            if let requestedBy = request.requestedBy {
                avatarImageView(for: requestedBy)
                Text(requestedBy.displayName)
                    .font(.body)
                    .foregroundColor(.white)
            }
        }
    }

    @ViewBuilder
    private func avatarImageView(for user: User) -> some View {
        if let avatar = user.avatar, !avatar.isEmpty {
            // Avatar is a path like "/avatarproxy/xxx?v=xxx" - build full URL with server
            let serverURL = UserDefaults.standard.string(forKey: "seerr_base_url") ?? ""
            let fullAvatarURL = "\(serverURL)\(avatar)"
            let avatarURL = URL(string: fullAvatarURL)

            // Build KFImage with authentication if needed
            let kfImage = KFImage(avatarURL)
                .placeholder {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }

            // Apply authentication headers if we have a session cookie
            if let sessionCookie = UserDefaults.standard.string(forKey: "sessionCookie") {
                let modifier = AnyModifier { request in
                    var r = request
                    r.setValue("connect.sid=\(sessionCookie)", forHTTPHeaderField: "Cookie")
                    return r
                }
                kfImage
                    .requestModifier(modifier)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                kfImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }
        } else {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray)
        }
    }

    private var dateView: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.body)
                .foregroundColor(.gray)
            Text(relativeTime)
                .font(.body)
                .foregroundColor(.gray)
        }
    }

    @ViewBuilder
    private var cancelButtonView: some View {
        if request.status == .pending && onCancel != nil {
            Button {
                onCancel?()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                    Text("Cancel Request")
                }
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.red.opacity(0.8))
                )
            }
            .buttonStyle(.borderless)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(isFocused ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .strokeBorder(isFocused ? Color.white.opacity(0.5) : Color.clear, lineWidth: 3)
    }

    // MARK: - Computed Properties
    private var mediaType: MediaType {
        request.media?.mediaType ?? .movie
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = dateFormatter.date(from: request.createdAt) {
            return formatter.localizedString(for: date, relativeTo: Date())
        }

        // Fallback: try without fractional seconds
        dateFormatter.formatOptions = [.withInternetDateTime]
        if let date = dateFormatter.date(from: request.createdAt) {
            return formatter.localizedString(for: date, relativeTo: Date())
        }

        return "recently"
    }
}

/// Small media type badge
struct MediaTypeBadgeView: View {
    let mediaType: MediaType

    var body: some View {
        Text(mediaType == .movie ? "MOVIE" : "SERIES")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(mediaType == .movie ? Color.Seerr.movieBadge : Color.Seerr.seriesBadge)
            )
    }
}
