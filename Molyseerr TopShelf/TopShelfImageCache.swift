//
//  TopShelfImageCache.swift
//  Molyseerr
//
//  Created by Claude on 02/01/2026.
//

import Foundation
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers

/// Image cache for TopShelf extension
/// Downloads and caches images locally for TopShelf display
/// TopShelf extensions have memory limits, so we cache images to disk
class TopShelfImageCache {

    // MARK: - Singleton

    static let shared = TopShelfImageCache()

    // MARK: - Properties

    private let fileManager = FileManager.default
    private let cacheDirectory: URL?
    private let urlSession: URLSession
    
    private lazy var sessionConfiguration: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        return config
    }()

    // MARK: - Initialization

    private init() {
        // Configure URLSession for extension
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.urlSession = URLSession(configuration: config)

        // Try App Group first (best for production), fallback to extension cache (works for testing)
        var cacheDir: URL?

        // Attempt 1: App Group (production - allows SpringBoard to read files)
        if let appGroupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.molycorp.Molyseerr.shared") {
            let appGroupCache = appGroupURL.appendingPathComponent("TopShelfImages", isDirectory: true)
            do {
                try fileManager.createDirectory(at: appGroupCache, withIntermediateDirectories: true, attributes: nil)
                print("📁 Using App Group cache: \(appGroupCache.path)")
                cacheDir = appGroupCache
            } catch {
                print("⚠️ App Group not accessible: \(error.localizedDescription)")
                print("   This is expected on physical devices without proper provisioning")
            }
        }

        // Attempt 2: Extension's temp directory (fallback for testing)
        if cacheDir == nil {
            if let tempURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                let tempCache = tempURL.appendingPathComponent("TopShelfImages", isDirectory: true)
                do {
                    try fileManager.createDirectory(at: tempCache, withIntermediateDirectories: true, attributes: nil)
                    print("📁 Using extension cache (fallback): \(tempCache.path)")
                    print("   ⚠️ This may not work on physical Apple TV due to sandbox restrictions")
                    cacheDir = tempCache
                } catch {
                    print("❌ Failed to create cache directory: \(error.localizedDescription)")
                }
            }
        }

        if let finalCacheDir = cacheDir {
            // Verify it's writable
            let testFile = finalCacheDir.appendingPathComponent(".test")
            let testData = Data("test".utf8)
            do {
                try testData.write(to: testFile)
                try fileManager.removeItem(at: testFile)
                print("✅ Cache directory is writable")
                self.cacheDirectory = finalCacheDir
            } catch {
                print("❌ Cache directory not writable: \(error.localizedDescription)")
                self.cacheDirectory = nil
            }
        } else {
            print("❌ No cache directory available")
            self.cacheDirectory = nil
        }
    }

    // MARK: - Private Methods
    
    /// Optimize image using ImageIO for efficient downsampling
    /// This method doesn't load full image in memory, using thumbnailing instead
    private func optimizeImageForTopShelf(_ data: Data) -> Data? {
        // Use ImageIO for memory-efficient image processing
        // This creates a thumbnail WITHOUT loading the full image in memory
        
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("❌ Failed to create image source")
            return nil
        }
        
        // Target dimensions for TopShelf
        // Use 1920x1080 (Full HD) for optimal quality on Apple TV
        // We'll use aggressive compression instead to save memory
        let maxDimension = 1920
        
        // Options for thumbnail generation - this is the KEY to memory efficiency
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            // Important: don't cache the decoded image
            kCGImageSourceShouldCache: false
        ]
        
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            print("❌ Failed to create thumbnail")
            return nil
        }
        
        // Create destination for JPEG output
        let outputData = NSMutableData()
        guard let imageDestination = CGImageDestinationCreateWithData(outputData, UTType.jpeg.identifier as CFString, 1, nil) else {
            print("❌ Failed to create image destination")
            return nil
        }

        // CRITICAL: Use simple compression settings for maximum hardware compatibility
        // ImageIO with kCGImageSourceCreateThumbnailFromImageAlways already creates baseline JPEG
        // The thumbnail generation strips progressive encoding and normalizes color space automatically
        let destinationProperties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.60 // Aggressive compression for small file size
        ]

        CGImageDestinationAddImage(imageDestination, thumbnail, destinationProperties as CFDictionary)
        
        guard CGImageDestinationFinalize(imageDestination) else {
            print("❌ Failed to finalize image")
            return nil
        }
        
        let originalSize = Double(data.count) / 1024.0
        let optimizedSize = Double(outputData.length) / 1024.0
        let reduction = ((originalSize - optimizedSize) / originalSize) * 100
        
        print("🎨 Image optimized (ImageIO): \(Int(originalSize)) KB → \(Int(optimizedSize)) KB (\(reduction > 0 ? "-" : "+")\(Int(abs(reduction)))%)")
        print("   Method: Memory-efficient thumbnail generation")
        
        return outputData as Data
    }

    // MARK: - Public Methods

    /// Cache an image from a remote URL
    /// - Parameters:
    ///   - url: Remote image URL
    ///   - identifier: Unique identifier for this image
    /// - Returns: Local file URL for the cached image
    func cacheImage(from url: URL, identifier: String) async throws -> URL {
        guard let cacheDirectory = cacheDirectory else {
            print("❌ Cache directory not found")
            throw CacheError.directoryNotFound
        }

        // Verify cache directory exists and is writable
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            print("⚠️ Cache directory missing, recreating...")
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: [
                    .posixPermissions: 0o755
                ])
            } catch {
                print("❌ Failed to recreate cache directory: \(error.localizedDescription)")
                throw CacheError.directoryNotFound
            }
        }

        // Create filename from identifier with version tag
        // v5 = App Group storage + JPEG baseline + sRGB (hardware compatibility fix)
        let filename = identifier.replacingOccurrences(of: "/", with: "_") + "_v5.jpg"
        let localURL = cacheDirectory.appendingPathComponent(filename)

        // Check if optimized image is already cached
        if fileManager.fileExists(atPath: localURL.path) {
            // Verify the file is readable and not corrupted
            if let cachedData = try? Data(contentsOf: localURL), cachedData.count > 0 {
                print("✅ Using cached optimized image: \(filename)")
                return localURL
            } else {
                // File exists but is corrupted, delete it
                print("⚠️ Corrupted cache file, deleting: \(filename)")
                try? fileManager.removeItem(at: localURL)
            }
        }
        
        // Clean up old versions if they exist
        for oldVersion in ["", "_v2", "_v3", "_v4"] {
            let oldFilename = identifier.replacingOccurrences(of: "/", with: "_") + "\(oldVersion).jpg"
            let oldURL = cacheDirectory.appendingPathComponent(oldFilename)
            if fileManager.fileExists(atPath: oldURL.path) {
                print("🧹 Removing old version: \(oldFilename)")
                try? fileManager.removeItem(at: oldURL)
            }
        }

        // Download and optimize image
        do {
            let (data, response) = try await urlSession.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("❌ Cache failed: HTTP error for \(identifier)")
                throw CacheError.downloadFailed
            }

            guard data.count > 0, let optimizedData = optimizeImageForTopShelf(data) else {
                print("❌ Cache failed: Optimization error for \(identifier)")
                throw CacheError.downloadFailed
            }

            try optimizedData.write(to: localURL, options: [.atomic])

            let sizeKB = optimizedData.count / 1024
            print("✅ Cached \(identifier): \(sizeKB) KB")

            return localURL
        } catch let error as CacheError {
            throw error
        } catch {
            print("❌ Cache failed: \(error.localizedDescription) for \(identifier)")
            throw CacheError.downloadFailed
        }
    }

    /// Clear all cached images
    func clearCache() {
        guard let cacheDirectory = cacheDirectory else { return }

        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Get cache size in bytes
    func getCacheSize() -> Int64 {
        guard let cacheDirectory = cacheDirectory else { return 0 }

        var totalSize: Int64 = 0

        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }

        return totalSize
    }
}

// MARK: - Errors

enum CacheError: LocalizedError {
    case directoryNotFound
    case downloadFailed
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .directoryNotFound:
            return "Cache directory not found"
        case .downloadFailed:
            return "Failed to download image"
        case .fileNotFound:
            return "Cached file not found or corrupted"
        }
    }
}
