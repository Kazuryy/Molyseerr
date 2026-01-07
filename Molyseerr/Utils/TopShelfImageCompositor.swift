//
//  TopShelfImageCompositor.swift
//  Molyseerr
//
//  Created by Claude on 03/01/2026.
//

import UIKit
import Foundation

/// Composites backdrop and logo images for TopShelf display
/// Creates Apple TV+ style images with logo in top-left corner
class TopShelfImageCompositor {

    // MARK: - Singleton

    static let shared = TopShelfImageCompositor()

    // MARK: - Properties

    private let appGroupID = "group.com.molycorp.Molyseerr.shared"
    private var cacheDirectory: URL?
    private let fileManager = FileManager.default // ⚡️ Reuse FileManager instance
    private var cachedCompositeExists: [Int: Bool] = [:] // ⚡️ Cache existence checks

    // MARK: - Initialization

    private init() {
        setupCacheDirectory()
    }

    private func setupCacheDirectory() {
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            print("❌ Failed to access App Group container")
            return
        }

        cacheDirectory = containerURL.appendingPathComponent("Library/Caches/TopShelfComposites", isDirectory: true)

        // Create cache directory if it doesn't exist
        if let cacheDir = cacheDirectory {
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
    }

    // MARK: - Public API

    /// Composite backdrop and logo images
    /// - Parameters:
    ///   - backdropURL: URL to backdrop image
    ///   - logoURL: URL to logo image
    ///   - itemId: Unique identifier for caching
    /// - Returns: URL to composite image in App Group cache, or nil if failed
    func compositeImages(backdropURL: URL, logoURL: URL, itemId: Int) async throws -> URL? {
        // ⚡️ Check in-memory cache first (avoids file system check)
        if cachedCompositeExists[itemId] == true {
            if let cachedURL = getCachedCompositeURLFast(itemId: itemId) {
                print("✅ Using cached composite for item \(itemId) (in-memory check)")
                return cachedURL
            }
        }

        // ⚡️ Check if composite already exists on disk
        if let cachedURL = getCachedCompositeURL(itemId: itemId) {
            cachedCompositeExists[itemId] = true // Cache the result
            print("✅ Using cached composite for item \(itemId)")
            return cachedURL
        }

        print("🎨 Creating composite image for item \(itemId)")

        // ⚡️ Download images in parallel (already optimized)
        async let backdropData = URLSession.shared.data(from: backdropURL)
        async let logoData = URLSession.shared.data(from: logoURL)

        let (backdrop, logo) = try await (backdropData, logoData)

        guard let backdropImage = UIImage(data: backdrop.0),
              let logoImage = UIImage(data: logo.0) else {
            print("❌ Failed to decode images")
            return nil
        }

        // Create composite
        guard let compositeImage = composite(backdrop: backdropImage, logo: logoImage) else {
            print("❌ Failed to create composite")
            return nil
        }

        // Save to cache
        if let savedURL = saveComposite(compositeImage, itemId: itemId) {
            cachedCompositeExists[itemId] = true // Update in-memory cache
            return savedURL
        }

        return nil
    }

    /// Clear all cached composite images
    func clearCache() {
        guard let cacheDir = cacheDirectory else { return }

        try? fileManager.removeItem(at: cacheDir)
        cachedCompositeExists.removeAll() // ⚡️ Clear in-memory cache
        setupCacheDirectory()
        print("🗑️ Cleared TopShelf composite image cache")
    }

    // MARK: - Private Methods

    /// Composite backdrop and logo (Apple TV+ style)
    private func composite(backdrop: UIImage, logo: UIImage) -> UIImage? {
        // Target size for backdrop (1920x1080 for 1x, will be scaled for 2x)
        let targetSize = CGSize(width: 1920, height: 1080)

        // Logo positioning (top-left with padding)
        let logoPadding: CGFloat = 80
        let logoMaxWidth: CGFloat = 500 // Max logo width

        // Calculate logo size (maintain aspect ratio)
        let logoAspectRatio = logo.size.width / logo.size.height
        let logoHeight = min(logo.size.height, 200)
        let logoWidth = min(logoHeight * logoAspectRatio, logoMaxWidth)
        let logoSize = CGSize(width: logoWidth, height: logoHeight)

        // Create graphics context
        let renderer = UIGraphicsImageRenderer(size: targetSize)

        let compositeImage = renderer.image { context in
            // Draw backdrop (fill entire canvas)
            backdrop.draw(in: CGRect(origin: .zero, size: targetSize))

            // Draw logo in top-left corner with padding
            let logoOrigin = CGPoint(x: logoPadding, y: logoPadding)
            logo.draw(in: CGRect(origin: logoOrigin, size: logoSize))
        }

        return compositeImage
    }

    /// Save composite image to cache
    private func saveComposite(_ image: UIImage, itemId: Int) -> URL? {
        guard let cacheDir = cacheDirectory else { return nil }

        let fileURL = cacheDir.appendingPathComponent("composite_\(itemId).jpg")

        // Convert to JPEG with high quality
        guard let jpegData = image.jpegData(compressionQuality: 0.90) else {
            print("❌ Failed to convert composite to JPEG")
            return nil
        }

        do {
            try jpegData.write(to: fileURL)
            print("✅ Saved composite image: \(fileURL.path)")
            return fileURL
        } catch {
            print("❌ Failed to save composite: \(error)")
            return nil
        }
    }

    /// Get cached composite URL if it exists (with file system check)
    private func getCachedCompositeURL(itemId: Int) -> URL? {
        guard let cacheDir = cacheDirectory else { return nil }

        let fileURL = cacheDir.appendingPathComponent("composite_\(itemId).jpg")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return fileURL
    }

    /// ⚡️ Fast composite URL retrieval (skips file system check, uses in-memory cache)
    private func getCachedCompositeURLFast(itemId: Int) -> URL? {
        guard let cacheDir = cacheDirectory else { return nil }
        return cacheDir.appendingPathComponent("composite_\(itemId).jpg")
    }
}
