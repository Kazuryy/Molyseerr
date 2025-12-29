//
//  MainTabView.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI

/// Main tab navigation for tvOS app
/// Three main sections: Discover, Movies, and TV Shows
struct MainTabView: View {
    @EnvironmentObject var configManager: ConfigManager

    var body: some View {
        TabView {
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "star.fill")
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
