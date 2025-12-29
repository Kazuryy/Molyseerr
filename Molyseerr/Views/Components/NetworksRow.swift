//
//  NetworksRow.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI

/// Horizontal row of network cards
/// Hardcoded list of major TV networks
struct NetworksRow: View {
    let slider: DiscoverSlider
    @Binding var selectedNetwork: Company?

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
                    ForEach(Company.networks) { network in
                        CompanyCard(company: network) {
                            selectedNetwork = network
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
            NetworksRow(
                slider: DiscoverSlider(
                    id: 1,
                    type: .networks,
                    order: 1,
                    isBuiltIn: true,
                    enabled: true,
                    title: nil,
                    data: nil,
                    createdAt: "",
                    updatedAt: ""
                ),
                selectedNetwork: .constant(nil)
            )
        }
    }
}
