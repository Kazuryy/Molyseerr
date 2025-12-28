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
        HStack(spacing: 20) {
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
                    .frame(width: 150)
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 225)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }

            // Info
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(2)

                // Metadata
                HStack(spacing: 8) {
                    // Media Type Badge
                    MediaTypeBadgeView(mediaType: mediaType)

                    // Status Badge
                    StatusBadge(status: request.status)
                }

                // Requested by
                if let requestedBy = request.requestedBy {
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("Requested by \(requestedBy.displayName)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                // Request date
                Text("Requested \(relativeTime)")
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()

                // Actions
                if request.status == .pending && onCancel != nil {
                    Button {
                        onCancel?()
                    } label: {
                        Text("Cancel Request")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.red, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .shadow(radius: isFocused ? 16 : 8)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
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
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(mediaType == .movie ? Color.Seerr.movieBadge : Color.Seerr.seriesBadge)
            )
    }
}
