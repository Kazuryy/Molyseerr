//
//  MoviesView.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI
import Combine

/// Movies page - Browse all movies with comprehensive filtering
/// Direct access to full movie catalog with advanced filters
struct MoviesView: View {
    @EnvironmentObject var configManager: ConfigManager

    var body: some View {
        AllMoviesView(category: .all)
    }
}

#Preview {
    MoviesView()
        .environmentObject(ConfigManager())
}
