//
//  StudiosRow.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI

/// Horizontal row of studio cards
/// Hardcoded list of major movie studios
struct StudiosRow: View {
    let slider: DiscoverSlider
    @Binding var selectedStudio: Company?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Text(slider.displayTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.leading, 48)

            // Horizontal carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 40) {
                    ForEach(Company.studios) { studio in
                        CompanyCard(company: studio) {
                            selectedStudio = studio
                        }
                    }
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 30) // Prevent clipping on focus scale
            }
            .scrollClipDisabled()
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        NavigationStack {
            StudiosRow(
                slider: DiscoverSlider(
                    id: 1,
                    type: .studios,
                    order: 1,
                    isBuiltIn: true,
                    enabled: true,
                    title: nil,
                    data: nil,
                    createdAt: "",
                    updatedAt: ""
                ),
                selectedStudio: .constant(nil)
            )
        }
    }
}
