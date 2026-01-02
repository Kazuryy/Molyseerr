//
//  ContentProvider.swift
//  Molyseerr TopShelf
//
//  Created by Ronan Jacques on 02/01/2026.
//

import TVServices
import Foundation

/// TopShelf Content Provider
/// Provides dynamic content for the tvOS home screen TopShelf
class ContentProvider: TVTopShelfContentProvider {

    // MARK: - Properties

    private let tmdbService = TMDBService.shared
    private let imageCache = TopShelfImageCache.shared
    private let settings = TopShelfSettings.shared

    // MARK: - TVTopShelfContentProvider

    override func loadTopShelfContent() async -> (any TVTopShelfContent)? {
        print("🔥 TopShelf: loadTopShelfContent called")

        do {
            let content = try await fetchTopShelfContent()
            print("✅ TopShelf: Content created successfully")
            return content
        } catch {
            print("❌ TopShelf error: \(error)")
            return nil
        }
    }

    // MARK: - Content Fetching

    private func fetchTopShelfContent() async throws -> TVTopShelfContent? {
        let displayMode = settings.displayMode
        let contentSource = settings.contentSource

        print("📺 Display mode: \(displayMode.displayName)")
        print("📺 Content source: \(contentSource.displayName)")

        switch displayMode {
        case .hero:
            return try await createCarouselContent(source: contentSource)
        case .sectioned:
            return try await createSectionedContent(source: contentSource)
        }
    }

    // MARK: - Carousel Mode (Apple TV+ style - Full screen)

    private func createCarouselContent(source: TopShelfContentSource) async throws -> TVTopShelfCarouselContent {
        print("🎬 Creating carousel content for source: \(source.displayName)")

        // Fetch more items like Apple TV+ (6-8 items)
        // We'll cache images in background but only reference them
        let items = try await fetchMediaItems(for: source, limit: 8)
        print("📦 Fetched \(items.count) items from TMDB")

        var carouselItems: [TVTopShelfCarouselItem] = []

        // Process items sequentially to avoid memory spikes
        for (index, item) in items.enumerated() {
            print("\n📝 Processing item \(index + 1)/\(items.count): \(item.displayTitle)")

            // Use backdrop for full-screen hero images
            guard let backdropPath = item.backdropPath,
                  let imageURL = URL(string: "https://image.tmdb.org/t/p/w1280\(backdropPath)") else {
                print("⚠️ No backdrop for \(item.displayTitle)")
                continue
            }

            print("🖼️ Using REMOTE URL directly: \(imageURL.absoluteString)")

            // CRITICAL TEST: Use remote URLs directly instead of local cache
            // This bypasses sandbox issues to test if images can display at all
            // Downsides: No offline support, slower, bandwidth usage
            // But if this works → confirms sandbox was the problem

            // Create carousel item - this is lightweight, just metadata
            let carouselItem = TVTopShelfCarouselItem(identifier: "item_\(item.id)")

            // Set REMOTE image URLs directly (tvOS will download on demand)
            carouselItem.setImageURL(imageURL, for: .screenScale1x)
            carouselItem.setImageURL(imageURL, for: .screenScale2x)

            print("✅ Using remote image URL (no cache)")

            // Set metadata
            carouselItem.title = item.displayTitle
            carouselItem.contextTitle = item.isMovie ? "Movie" : "TV Show"

            if let overview = item.overview {
                carouselItem.summary = overview
            }

            // Deep link
            let mediaType = item.isMovie ? "movie" : "tv"
            if let deepLinkURL = URL(string: "molyseerr://media/\(mediaType)/\(item.id)") {
                carouselItem.displayAction = TVTopShelfAction(url: deepLinkURL)
                carouselItem.playAction = TVTopShelfAction(url: deepLinkURL)
                print("🔗 Deep link: \(deepLinkURL.absoluteString)")
            }

            carouselItems.append(carouselItem)
            print("✅ Created carousel item: \(item.displayTitle)")
        }

        print("\n🎬 Created \(carouselItems.count) carousel items")

        // WORKAROUND: Use .actions style instead of .details
        // .details has known bugs on Apple TV 2022 hardware causing black screens
        // .actions is more reliable and still provides good visual quality
        let content = TVTopShelfCarouselContent(style: .actions, items: carouselItems)

        print("✅ Carousel content created with .actions style (hardware-compatible)")
        return content
    }

    // MARK: - Sectioned Mode (Netflix style)

    private func createSectionedContent(source: TopShelfContentSource) async throws -> TVTopShelfSectionedContent {
        print("📚 Creating sectioned content for source: \(source.displayName)")

        let items = try await fetchMediaItems(for: source, limit: 6)
        print("📦 Fetched \(items.count) items from TMDB")

        var sectionItems: [TVTopShelfSectionedItem] = []

        for (index, item) in items.enumerated() {
            print("\n📝 Processing item \(index + 1)/\(items.count): \(item.displayTitle)")

            // Use poster for sectioned content
            guard let posterPath = item.posterPath,
                  let imageURL = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") else {
                print("⚠️ No poster for \(item.displayTitle)")
                continue
            }

            print("🖼️ Using REMOTE URL directly: \(imageURL.absoluteString)")

            let sectionItem = TVTopShelfSectionedItem(identifier: "item_\(item.id)")

            // Set image shape and REMOTE URL
            sectionItem.imageShape = .poster
            sectionItem.setImageURL(imageURL, for: .screenScale1x)
            sectionItem.setImageURL(imageURL, for: .screenScale2x)

            print("✅ Using remote image URL (no cache)")

            sectionItem.title = item.displayTitle

            // Create deep link
            let mediaType = item.isMovie ? "movie" : "tv"
            if let deepLinkURL = URL(string: "molyseerr://media/\(mediaType)/\(item.id)") {
                sectionItem.playAction = TVTopShelfAction(url: deepLinkURL)
                print("🔗 Deep link: \(deepLinkURL.absoluteString)")
            }

            sectionItems.append(sectionItem)
            print("✅ Created section item: \(item.displayTitle)")
        }

        print("\n📚 Created \(sectionItems.count) section items")

        // Create section
        let section = TVTopShelfItemCollection(items: sectionItems)
        section.title = source.displayName

        let content = TVTopShelfSectionedContent(sections: [section])
        print("✅ Sectioned content created")

        return content
    }

    // MARK: - Data Fetching

    private func fetchMediaItems(for source: TopShelfContentSource, limit: Int) async throws -> [TMDBMediaItem] {
        switch source {
        case .trending:
            let response = try await tmdbService.getTrending(mediaType: "all", timeWindow: "week", page: 1)
            return Array(response.results.prefix(limit))

        case .popularMovies:
            let response = try await tmdbService.getTrending(mediaType: "movie", timeWindow: "week", page: 1)
            return Array(response.results.prefix(limit))

        case .popularTV:
            let response = try await tmdbService.getTrending(mediaType: "tv", timeWindow: "week", page: 1)
            return Array(response.results.prefix(limit))

        case .watchlist:
            // TODO: Implement watchlist support
            let response = try await tmdbService.getTrending(mediaType: "all", timeWindow: "week", page: 1)
            return Array(response.results.prefix(limit))
        }
    }
}
