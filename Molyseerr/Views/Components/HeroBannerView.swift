//
//  HeroBannerView.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import SwiftUI
import Kingfisher

/// Hero banner component for featured content
/// Apple TV+ style with large backdrop, title overlay, and action buttons
/// Reference: APPLE_TV_DESIGN_REFERENCE.md Section 2.2 (Hero Banner)
struct HeroBannerView: View {
    let item: MediaResult
    @FocusState private var focusedButton: FocusedButton?

    // MARK: - Constants
    private let bannerHeight: CGFloat = 820  // Slightly taller for tvOS
    private let contentBottomPadding: CGFloat = 80
    private let contentLeadingPadding: CGFloat = 90  // tvOS safe area

    enum FocusedButton: Hashable {
        case play
        case info
        case next
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background backdrop - edge to edge
            backdropView

            // Gradient overlay for text readability
            gradientOverlay

            // Content overlay (metadata, title, description, buttons)
            contentOverlay
                .padding(.leading, contentLeadingPadding)
                .padding(.bottom, contentBottomPadding)
                .padding(.trailing, contentLeadingPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: bannerHeight)
        .edgesIgnoringSafeArea(.horizontal)
    }

    // MARK: - Subviews

    private var backdropView: some View {
        ZStack {
            // Backdrop image using Kingfisher (TECH_RULES.md: original size for hero banner)
            if let backdropURL = TMDBImageHelper.backdropURL(path: item.backdropPath) {
                KFImage(backdropURL)
                    .placeholder {
                        // Placeholder while loading
                        Color(red: 0.1, green: 0.15, blue: 0.3)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(2.0)
                            )
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: bannerHeight)
                    .clipped()
            } else {
                // Fallback if no backdrop available
                Color(red: 0.1, green: 0.15, blue: 0.3)
                    .overlay(
                        // Media type watermark
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: item.mediaType == .movie ? "film" : "tv")
                                    .font(.system(size: 180))
                                    .foregroundColor(.white.opacity(0.05))
                                Spacer()
                            }
                            Spacer()
                        }
                    )
            }
        }
    }

    private var gradientOverlay: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .clear, location: 0.0),
                .init(color: .black.opacity(0.1), location: 0.3),
                .init(color: .black.opacity(0.4), location: 0.6),
                .init(color: .black.opacity(0.8), location: 0.85),
                .init(color: .black, location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var contentOverlay: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Metadata badges (Genre, Type, Rating)
            metadataBadges

            // Title (will be replaced by logo image in future)
            Text(item.title)
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

            // Description - shorter like Apple TV+
            if let overview = item.overview {
                Text(overview)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
                    .frame(maxWidth: 900, alignment: .leading)
            }

            // Action buttons
            actionButtons
                .padding(.top, 8)
        }
    }

    private var metadataBadges: some View {
        HStack(spacing: 8) {
            // Media type badge
            Text(item.mediaType == .movie ? "Movie" : "Series")
                .font(.callout)
                .fontWeight(.medium)

            Text("·")
                .font(.callout)

            // TODO: Add genre from API when available
            Text("Science-fiction")
                .font(.callout)

            Text("·")
                .font(.callout)

            // TODO: Add rating from API
            Text("12+")
                .font(.callout)
        }
        .foregroundColor(.white.opacity(0.8))
    }

    private var actionButtons: some View {
        HStack(spacing: 24) {
            // More Info button (navigate to details) - Apple TV+ style
            NavigationLink(destination: MediaDetailView(mediaResult: item)) {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                    Text("More Info")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 18)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(12)
            }
            .buttonStyle(.borderless)
            .focusable()
            .focused($focusedButton, equals: .play)
            .scaleEffect(focusedButton == .play ? 1.08 : 1.0)
            .shadow(color: focusedButton == .play ? .white.opacity(0.3) : .clear, radius: 20)
            .animation(.easeInOut(duration: 0.15), value: focusedButton)

            // Add to List button - circular icon style
            Button {
                print("Add to list: \(item.title)")
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 60, height: 60)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(.borderless)
            .focusable()
            .focused($focusedButton, equals: .info)
            .scaleEffect(focusedButton == .info ? 1.15 : 1.0)
            .shadow(color: focusedButton == .info ? .white.opacity(0.4) : .clear, radius: 15)
            .animation(.easeInOut(duration: 0.15), value: focusedButton)

            // Next/More button - chevron
            Button {
                print("Next: \(item.title)")
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 60, height: 60)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(.borderless)
            .focusable()
            .focused($focusedButton, equals: .next)
            .scaleEffect(focusedButton == .next ? 1.15 : 1.0)
            .shadow(color: focusedButton == .next ? .white.opacity(0.4) : .clear, radius: 15)
            .animation(.easeInOut(duration: 0.15), value: focusedButton)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        HeroBannerView(item: .movie(MovieResult(
            id: 1,
            adult: false,
            backdropPath: nil,
            posterPath: nil,
            genreIds: [28, 12, 878],
            originalLanguage: "en",
            originalTitle: "Epic Adventure Movie",
            overview: "A thrilling adventure across space and time, where heroes must unite to save the universe from an ancient threat that could destroy everything they hold dear.",
            popularity: 1500,
            releaseDate: "2025-03-15",
            firstAirDate: nil,
            title: "Epic Adventure Movie",
            name: nil,
            originCountry: nil,
            originalName: nil,
            video: false,
            voteAverage: 8.5,
            voteCount: 10000,
            mediaType: "movie",
            mediaInfo: nil
        )))
    }
}
