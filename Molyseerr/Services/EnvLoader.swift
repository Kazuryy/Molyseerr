//
//  EnvLoader.swift
//  Molyseerr
//
//  Created by Kazuryy on 24/12/2025.
//

import Foundation

/// Loads environment variables from .env file
/// Used for development configuration (API keys, server URLs, etc.)
enum EnvLoader {

    // MARK: - Public Properties

    /// Seerr server base URL
    static var seerrBaseURL: String {
        return getEnvValue(for: "SEERR_BASE_URL") ?? "http://localhost:5055"
    }

    /// Seerr API key
    static var seerrApiKey: String {
        return getEnvValue(for: "SEERR_API_KEY") ?? ""
    }

    /// Request timeout in seconds
    static var timeout: TimeInterval {
        if let timeoutString = getEnvValue(for: "SEERR_TIMEOUT"),
           let timeoutValue = TimeInterval(timeoutString) {
            return timeoutValue
        }
        return 30.0 // Default timeout
    }

    // MARK: - Private Methods

    /// Cache for loaded environment variables
    private static var cachedEnvVars: [String: String]?

    /// Retrieves an environment variable value
    /// - Parameter key: The environment variable key
    /// - Returns: The value if found, nil otherwise
    private static func getEnvValue(for key: String) -> String? {
        // Load .env file if not already loaded
        if cachedEnvVars == nil {
            loadEnvFile()
        }

        return cachedEnvVars?[key]
    }

    /// Loads the .env file from the project root
    private static func loadEnvFile() {
        cachedEnvVars = [:]

        // Try to find .env file in common locations
        let possiblePaths = [
            // Development: project root using #file path
            URL(fileURLWithPath: #file)
                .deletingLastPathComponent() // Services/
                .deletingLastPathComponent() // Molyseerr/
                .deletingLastPathComponent() // Project root
                .appendingPathComponent(".env"),

            // Alternative: Bundle resource (if added to Xcode target)
            Bundle.main.url(forResource: ".env", withExtension: nil),

            // Absolute path for development (works in simulator)
            // Note: Update this path to match your local setup
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Molyseerr/.env")
        ].compactMap { $0 }

        #if DEBUG
        print("🔍 Searching for .env file in:")
        for path in possiblePaths {
            let exists = FileManager.default.fileExists(atPath: path.path)
            print("  \(exists ? "✅" : "❌") \(path.path)")
        }
        #endif

        for envPath in possiblePaths {
            if FileManager.default.fileExists(atPath: envPath.path) {
                parseEnvFile(at: envPath)
                return
            }
        }

        #if DEBUG
        print("⚠️ .env file not found")
        #endif
    }

    /// Parses the .env file and populates the cache
    /// - Parameter url: URL to the .env file
    private static func parseEnvFile(at url: URL) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return
        }

        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            // Skip comments and empty lines
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }

            // Parse KEY=VALUE
            let parts = trimmedLine.components(separatedBy: "=")
            guard parts.count >= 2 else { continue }

            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1...].joined(separator: "=").trimmingCharacters(in: .whitespaces)

            cachedEnvVars?[key] = value
        }

        #if DEBUG
        print("✅ Loaded .env file from: \(url.path)")
        print("📡 Seerr URL: \(seerrBaseURL)")
        print("🔑 API Key: \(seerrApiKey.isEmpty ? "❌ Missing" : "✅ Configured")")
        #endif
    }
}
