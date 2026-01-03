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

    private let tmdbService = TMDBService.shared // Fallback for legacy mode
    private let seerrService = TopShelfSeerrService.shared
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

        // Configure Seerr service
        seerrService.configure(baseURL: settings.seerrURL, apiKey: settings.seerrAPIKey)

        // Migrate legacy settings if needed
        settings.migrateLegacySettings()

        let selectedSliders = settings.selectedSliders

        print("📺 Display mode: \(displayMode.displayName)")
        print("📺 Selected sliders: \(selectedSliders.count)")

        // If no sliders selected, fall back to legacy mode
        if selectedSliders.isEmpty {
            print("⚠️ No sliders selected - using legacy mode")
            let contentSource = settings.contentSource
            print("📺 Legacy content source: \(contentSource.displayName)")

            switch displayMode {
            case .hero:
                return try await createLegacyCarouselContent(source: contentSource)
            case .sectioned:
                return try await createLegacySectionedContent(source: contentSource)
            }
        }

        // New dynamic slider mode
        switch displayMode {
        case .hero:
            // Hero mode: use first slider only
            guard let firstSlider = selectedSliders.first else {
                throw ContentError.noSlidersSelected
            }
            print("📺 Hero mode: Using slider '\(firstSlider.title)'")
            return try await createCarouselContent(slider: firstSlider)
        case .sectioned:
            // Sectioned mode: use all selected sliders (max 4)
            let sliders = Array(selectedSliders.prefix(4))
            print("📺 Sectioned mode: Using \(sliders.count) sliders")
            return try await createSectionedContent(sliders: sliders)
        }
    }

    enum ContentError: Error {
        case noSlidersSelected
        case seerrNotConfigured
    }

    // MARK: - New Dynamic Slider Mode

    /// Create carousel content from a Seerr slider
    private func createCarouselContent(slider: TopShelfSliderConfig) async throws -> TVTopShelfCarouselContent {
        print("🎬 Creating carousel content for slider: \(slider.title)")

        guard seerrService.isConfigured else {
            throw ContentError.seerrNotConfigured
        }

        let items = try await seerrService.getSliderContent(slider: slider, limit: 12)
        print("📦 Fetched \(items.count) items from Seerr")

        var carouselItems: [TVTopShelfCarouselItem] = []

        for (index, item) in items.enumerated() {
            print("\n📝 Processing item \(index + 1)/\(items.count): \(item.title)")

            guard let backdropPath = item.backdropPath,
                  let imageURL = URL(string: "https://image.tmdb.org/t/p/w1280\(backdropPath)") else {
                print("⚠️ No backdrop for \(item.title)")
                continue
            }

            let carouselItem = TVTopShelfCarouselItem(identifier: "item_\(item.id)")

            // Use composite image if logo is available, otherwise use plain backdrop
            if let logoPath = item.logoPath, !logoPath.isEmpty {
                // Composite image URL will be stored in cache with special naming
                // Format: backdrop_with_logo_{id}.jpg in App Group container
                if let compositeURL = getCompositeImageURL(itemId: item.id) {
                    print("🎨 Using composite image with logo for '\(item.title)'")
                    carouselItem.setImageURL(compositeURL, for: .screenScale1x)
                    carouselItem.setImageURL(compositeURL, for: .screenScale2x)
                } else {
                    // Fallback to plain backdrop
                    print("⚠️ No composite image found, using plain backdrop for '\(item.title)'")
                    carouselItem.setImageURL(imageURL, for: .screenScale1x)
                    carouselItem.setImageURL(imageURL, for: .screenScale2x)
                }
            } else {
                // No logo - use plain backdrop
                carouselItem.setImageURL(imageURL, for: .screenScale1x)
                carouselItem.setImageURL(imageURL, for: .screenScale2x)
            }

            carouselItem.title = item.title
            carouselItem.contextTitle = item.mediaType == "movie" ? "Movie" : "TV Show"

            if let overview = item.overview {
                carouselItem.summary = overview
            }

            // Deep link
            if let deepLinkURL = URL(string: "molyseerr://media/\(item.mediaType)/\(item.id)") {
                carouselItem.displayAction = TVTopShelfAction(url: deepLinkURL)
                carouselItem.playAction = TVTopShelfAction(url: deepLinkURL)
            }

            carouselItems.append(carouselItem)
        }

        print("\n🎬 Created \(carouselItems.count) carousel items")

        let content = TVTopShelfCarouselContent(style: .actions, items: carouselItems)
        return content
    }

    /// Create sectioned content from multiple Seerr sliders
    private func createSectionedContent(sliders: [TopShelfSliderConfig]) async throws -> TVTopShelfSectionedContent {
        print("📚 Creating sectioned content for \(sliders.count) sliders")

        guard seerrService.isConfigured else {
            throw ContentError.seerrNotConfigured
        }

        var sections: [TVTopShelfItemCollection<TVTopShelfSectionedItem>] = []

        for slider in sliders {
            print("\n📂 Processing slider: \(slider.title)")

            do {
                let items = try await seerrService.getSliderContent(slider: slider, limit: 6)
                print("📦 Fetched \(items.count) items for '\(slider.title)'")

                var sectionItems: [TVTopShelfSectionedItem] = []

                for item in items {
                    // Use poster if available, fallback to backdrop
                    let imagePath = item.posterPath ?? item.backdropPath
                    guard let imagePath = imagePath,
                          let imageURL = URL(string: "https://image.tmdb.org/t/p/w500\(imagePath)") else {
                        print("⚠️ Skipping item '\(item.title)' - no poster or backdrop")
                        continue
                    }

                    let sectionItem = TVTopShelfSectionedItem(identifier: "item_\(item.id)")
                    sectionItem.imageShape = .poster
                    sectionItem.setImageURL(imageURL, for: .screenScale1x)
                    sectionItem.setImageURL(imageURL, for: .screenScale2x)
                    sectionItem.title = item.title

                    if let deepLinkURL = URL(string: "molyseerr://media/\(item.mediaType)/\(item.id)") {
                        sectionItem.playAction = TVTopShelfAction(url: deepLinkURL)
                    }

                    sectionItems.append(sectionItem)
                }

                if !sectionItems.isEmpty {
                    let section = TVTopShelfItemCollection<TVTopShelfSectionedItem>(items: sectionItems)
                    section.title = slider.title
                    sections.append(section)
                    print("✅ Created section '\(slider.title)' with \(sectionItems.count) items")
                }
            } catch {
                print("⚠️ Failed to fetch slider '\(slider.title)': \(error)")
                // Continue with other sliders
            }
        }

        print("\n📚 Created \(sections.count) sections total")

        let content = TVTopShelfSectionedContent(sections: sections)
        return content
    }

    // MARK: - Legacy TMDB Mode (Fallback)

    private func createLegacyCarouselContent(source: TopShelfContentSource) async throws -> TVTopShelfCarouselContent {
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

    private func createLegacySectionedContent(source: TopShelfContentSource) async throws -> TVTopShelfSectionedContent {
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

    // MARK: - Helper Methods

    /// Get composite image URL from App Group cache
    private func getCompositeImageURL(itemId: Int) -> URL? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.molycorp.Molyseerr.shared") else {
            return nil
        }

        let cacheDir = containerURL.appendingPathComponent("Library/Caches/TopShelfComposites", isDirectory: true)
        let imageURL = cacheDir.appendingPathComponent("composite_\(itemId).jpg")

        // Check if file exists
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            return nil
        }

        return imageURL
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
