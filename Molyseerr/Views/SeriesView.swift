//
//  SeriesView.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI
import Combine

/// Series page - Browse all TV shows with comprehensive filtering
/// Direct access to full TV show catalog with advanced filters
struct SeriesView: View {
    @EnvironmentObject var configManager: ConfigManager

    var body: some View {
        AllSeriesView(category: .all)
    }
}

#Preview {
    SeriesView()
        .environmentObject(ConfigManager())
}
