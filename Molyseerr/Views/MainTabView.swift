//
//  MainTabView.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI

/// Main sidebar navigation for tvOS app (Apple TV+ style)
/// Features: Discover, Movies, TV Shows, Requests, Search, and Settings
// Environment key to track current tab
struct CurrentTabKey: EnvironmentKey {
    static let defaultValue: MainTabView.TabItem = .discover
}

extension EnvironmentValues {
    var currentTab: MainTabView.TabItem {
        get { self[CurrentTabKey.self] }
        set { self[CurrentTabKey.self] = newValue }
    }
}

struct MainTabView: View {
    @EnvironmentObject var configManager: ConfigManager
    @State private var selectedTab: TabItem = .discover
    @State private var tabViewID = UUID()

    enum TabItem: Equatable {
        case discover
        case movies
        case series
        case requests
        case search
        case profile
        case settings
    }

    var body: some View {
        TabView(selection: Binding(
            get: { selectedTab },
            set: { newTab in
                let oldTab = selectedTab
                selectedTab = newTab

                // Only reset if actually changed tabs
                if oldTab != newTab {
                    print("🔄 Tab changed: \(oldTab) → \(newTab) - clearing ALL navigation")
                    // Force complete TabView recreation to clear all navigation stacks
                    tabViewID = UUID()
                }
            }
        )) {
            NavigationStack {
                DiscoverView()
            }
            .tabItem {
                Label("Discover", systemImage: "star.fill")
            }
            .tag(TabItem.discover)
            .environmentObject(configManager)

            NavigationStack {
                MoviesView()
            }
            .tabItem {
                Label("Movies", systemImage: "film")
            }
            .tag(TabItem.movies)
            .environmentObject(configManager)

            NavigationStack {
                SeriesView()
            }
            .tabItem {
                Label("TV Shows", systemImage: "tv")
            }
            .tag(TabItem.series)
            .environmentObject(configManager)

            NavigationStack {
                RequestsView()
            }
            .tabItem {
                Label("Requests", systemImage: "list.bullet")
            }
            .tag(TabItem.requests)
            .environmentObject(configManager)

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(TabItem.search)
            .environmentObject(configManager)

            NavigationStack {
                ProfileView()
            }
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
        .id(tabViewID)  // Force complete recreation when ID changes
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    MainTabView()
        .environmentObject(ConfigManager())
}
