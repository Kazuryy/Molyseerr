//
//  MainTabView.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI

/// Main tab navigation for tvOS app
/// Four main sections: Discover, Movies, TV Shows, and Requests
struct MainTabView: View {
    @EnvironmentObject var configManager: ConfigManager

    var body: some View {
        TabView {
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "star.fill")
                }
                .environmentObject(configManager)

            MoviesView()
                .tabItem {
                    Label("Movies", systemImage: "film")
                }
                .environmentObject(configManager)

            SeriesView()
                .tabItem {
                    Label("TV Shows", systemImage: "tv")
                }
                .environmentObject(configManager)

            RequestsView()
                .tabItem {
                    Label("Requests", systemImage: "list.bullet")
                }
                .environmentObject(configManager)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(ConfigManager())
}
