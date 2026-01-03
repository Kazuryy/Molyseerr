//
//  MainTabView.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI

/// Main sidebar navigation for tvOS app (Apple TV+ style)
/// Features: Discover, Movies, TV Shows, Requests, Search, and Settings
struct MainTabView: View {
    @EnvironmentObject var configManager: ConfigManager
    @State private var selectedTab: TabItem = .discover

    enum TabItem {
        case discover
        case movies
        case series
        case requests
        case search
        case profile
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "star.fill")
                }
                .tag(TabItem.discover)
                .environmentObject(configManager)

            MoviesView()
                .tabItem {
                    Label("Movies", systemImage: "film")
                }
                .tag(TabItem.movies)
                .environmentObject(configManager)

            SeriesView()
                .tabItem {
                    Label("TV Shows", systemImage: "tv")
                }
                .tag(TabItem.series)
                .environmentObject(configManager)

            RequestsView()
                .tabItem {
                    Label("Requests", systemImage: "list.bullet")
                }
                .tag(TabItem.requests)
                .environmentObject(configManager)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(TabItem.search)
                .environmentObject(configManager)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(TabItem.profile)
                .environmentObject(configManager)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(TabItem.settings)
                .environmentObject(configManager)
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    MainTabView()
        .environmentObject(ConfigManager())
}
