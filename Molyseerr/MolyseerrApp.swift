//
//  MolyseerrApp.swift
//  Molyseerr
//
//  Created by Kazuryy on 23/12/2025.
//

import SwiftUI

@main
struct MolyseerrApp: App {

    init() {
        // Configure Seerr service with .env values
        configureSeerrService()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    // MARK: - Configuration

    /// Configures the Seerr service with environment variables
    private func configureSeerrService() {
        let baseURL = EnvLoader.seerrBaseURL
        let apiKey = EnvLoader.seerrApiKey

        SeerrService.shared.setBaseURL(baseURL)
        SeerrService.shared.setApiKey(apiKey)

        #if DEBUG
        if apiKey.isEmpty {
            print("⚠️ WARNING: SEERR_API_KEY is not set!")
            print("📝 Create a .env file from .env.example and add your API key")
        } else {
            print("✅ Seerr service configured successfully")
        }
        #endif
    }
}
