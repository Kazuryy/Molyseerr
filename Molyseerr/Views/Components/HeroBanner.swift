//
//  HeroBanner.swift
//  Molyseerr
//
//  Created by Claude on 31/12/2025.
//

import SwiftUI
import Kingfisher

/// Auto-rotating hero banner for Discover page (Apple TV+ style)
/// Displays backdrop, title, and metadata for featured content
struct HeroBanner: View {
    let items: [MediaResult]
    let rotationInterval: TimeInterval = 8.0  // Change every 8 seconds

    @State private var currentIndex = 0
    @State private var timer: Timer?

    // Constants
    private let bannerHeight: CGFloat = 900
    private let horizontalPadding: CGFloat = 90

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                if !items.isEmpty {
                    let currentItem = items[currentIndex]

                    // Backdrop image - extends to edges
                    backdropImageView(for: currentItem, width: geometry.size.width)
                        .id(currentIndex)  // Force view update on index change
                        .transition(.opacity)
                        .edgesIgnoringSafeArea(.all)

                    // Gradient overlay - stays visible during transitions
                    gradientOverlay
                        .edgesIgnoringSafeArea(.all)

                    // Content overlay with fixed positioning
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()

                        VStack(alignment: .leading, spacing: 20) {
                            // Title - fixed height (2 lines max)
                            Text(currentItem.title)
                                .font(.system(size: 70, weight: .bold))
                                .foregroundColor(.white)
                                .lineSpacing(-4)
                                .lineLimit(2)
                                .frame(height: 140, alignment: .bottom)  // Fixed height for 2 lines
                                .shadow(color: .black.opacity(0.8), radius: 10)

                            // Metadata row - fixed height
                            metadataRow(for: currentItem)
                                .frame(height: 30)  // Fixed height

                            // Overview - fixed height (3 lines max)
                            Text(currentItem.overview ?? "")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(4)
                                .lineLimit(3)
                                .frame(height: 120, alignment: .top)  // Fixed height for 3 lines
                                .shadow(color: .black.opacity(0.6), radius: 8)
                                .padding(.top, 8)

                            // Action buttons - fixed position
                            actionButtons(for: currentItem)
                                .padding(.top, 30)

                            // Page indicators - fixed position
                            pageIndicators
                                .padding(.top, 20)
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, 80)
                    }
                }
            }
            .frame(width: geometry.size.width, height: bannerHeight)
        }
        .frame(height: bannerHeight)
        .task {
            await loadWatchlistStatus()
        }
        .onAppear {
            startRotation()
        }
        .onDisappear {
            stopRotation()
        }
    }

    // MARK: - Subviews

    private func backdropImageView(for item: MediaResult, width: CGFloat) -> some View {
        // Backdrop image only (gradient is separate to avoid flicker during transitions)
        Group {
            if let backdropPath = item.backdropPath,
               let backdropURL = TMDBImageHelper.backdropURL(path: backdropPath, size: .original) {
                KFImage(backdropURL)
                    .placeholder {
                        Color(red: 0.1, green: 0.12, blue: 0.16)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: bannerHeight)
                    .clipped()
            } else {
                Color(red: 0.1, green: 0.12, blue: 0.16)
                    .frame(width: width, height: bannerHeight)
            }
        }
    }

    private var gradientOverlay: some View {
        // Gradient overlay for text readability - separate from backdrop to stay visible during transitions
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.3),
                Color(red: 17/255, green: 24/255, blue: 39/255).opacity(1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func metadataRow(for item: MediaResult) -> some View {
        HStack(spacing: 20) {
            // Year
            if let year = item.releaseYear {
                Text(year)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }

            // Media type badge
            HStack(spacing: 6) {
                Image(systemName: item.mediaType == .movie ? "film.fill" : "tv.fill")
                    .font(.system(size: 18))
                Text(item.mediaType == .movie ? "Movie" : "Series")
                    .font(.system(size: 22, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.8))

            // Rating
            if let rating = getVoteAverage(for: item), rating > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .shadow(color: .black.opacity(0.6), radius: 8)
    }

    private func actionButtons(for item: MediaResult) -> some View {
        HStack(spacing: 32) {  // Increased from 20 to 32 to prevent overlap when focused
            // Info/More Info button (Primary action)
            NavigationLink(value: item) {
                Label("More Info", systemImage: "info.circle.fill")
            }
            .buttonStyle(.actionPrimary)

            // Watchlist button (Custom style matching More Info)
            watchlistButton(for: item)
        }
    }

    @ViewBuilder
    private func watchlistButton(for item: MediaResult) -> some View {
        // Watchlist button with text label to match More Info sizing
        Button {
            toggleWatchlist(for: item)
        } label: {
            Label("Watchlist", systemImage: isInWatchlist(item) ? "star.fill" : "star")
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    isInWatchlist(item) ? .yellow : .white,
                    .white
                )
        }
        .buttonStyle(.actionSecondary)
    }

    private var pageIndicators: some View {
        HStack(spacing: 12) {
            ForEach(0..<min(items.count, 10), id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 10, height: 10)
                    .animation(.easeInOut, value: currentIndex)
            }
        }
    }

    // MARK: - Rotation Logic

    private func startRotation() {
        guard items.count > 1 else { return }

        timer = Timer.scheduledTimer(withTimeInterval: rotationInterval, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.8)) {
                currentIndex = (currentIndex + 1) % items.count
            }
        }
    }

    private func stopRotation() {
        timer?.invalidate()
        timer = nil
    }

    private func getVoteAverage(for item: MediaResult) -> Double? {
        switch item {
        case .movie(let movie):
            return movie.voteAverage
        case .tv(let tv):
            return tv.voteAverage
        }
    }

    // MARK: - Watchlist Actions

    @State private var watchlistItems: Set<Int> = []

    private func isInWatchlist(_ item: MediaResult) -> Bool {
        return watchlistItems.contains(item.id)
    }

    private func toggleWatchlist(for item: MediaResult) {
        Task {
            do {
                let tmdbId = item.id
                let mediaType = item.mediaType

                if isInWatchlist(item) {
                    // Remove from watchlist
                    try await SeerrService.shared.removeFromWatchlist(tmdbId: tmdbId)
                    watchlistItems.remove(tmdbId)
                    print("✅ Removed from watchlist: \(item.title)")
                } else {
                    // Add to watchlist
                    _ = try await SeerrService.shared.addToWatchlist(tmdbId: tmdbId, mediaType: mediaType, title: item.title)
                    watchlistItems.insert(tmdbId)
                    print("✅ Added to watchlist: \(item.title)")
                }
            } catch {
                print("❌ Failed to toggle watchlist: \(error)")
            }
        }
    }

    private func loadWatchlistStatus() async {
        do {
            let watchlist = try await SeerrService.shared.getWatchlist(page: 1)
            watchlistItems = Set(watchlist.compactMap { $0.tmdbId })
            print("✅ Loaded watchlist status: \(watchlistItems.count) items")
        } catch {
            print("❌ Failed to load watchlist: \(error)")
        }
    }
}

// MARK: - MediaResult Extension

extension MediaResult {
    var releaseYear: String? {
        switch self {
        case .movie(let movie):
            if let releaseDate = movie.releaseDate, !releaseDate.isEmpty {
                return String(releaseDate.prefix(4))
            }
        case .tv(let tv):
            if let firstAirDate = tv.firstAirDate, !firstAirDate.isEmpty {
                return String(firstAirDate.prefix(4))
            }
        }
        return nil
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        HeroBanner(items: [
            .movie(MovieResult(
                id: 1,
                adult: false,
                backdropPath: "/sample.jpg",
                posterPath: "/poster.jpg",
                genreIds: [28, 12],
                originalLanguage: "en",
                originalTitle: "Action Movie",
                overview: "An epic action movie with stunning visuals and amazing storytelling that will keep you on the edge of your seat.",
                popularity: 1250.5,
                releaseDate: "2024-03-15",
                firstAirDate: nil,
                title: "Action Movie",
                name: nil,
                originCountry: nil,
                originalName: nil,
                video: false,
                voteAverage: 8.5,
                voteCount: 12500,
                mediaType: "movie",
                mediaInfo: nil
            )),
            .tv(TVResult(
                id: 2,
                backdropPath: "/backdrop2.jpg",
                posterPath: "/poster2.jpg",
                genreIds: [18, 10765],
                originalLanguage: "en",
                originalName: "Drama Series",
                overview: "A compelling drama series that explores the depths of human emotion and complex relationships.",
                popularity: 980.2,
                firstAirDate: "2024-01-20",
                name: "Drama Series",
                voteAverage: 9.1,
                voteCount: 8900,
                originCountry: ["US"],
                mediaType: "tv",
                mediaInfo: nil
            ))
        ])
    }
}
