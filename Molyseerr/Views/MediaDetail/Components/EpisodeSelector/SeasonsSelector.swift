//
//  SeasonsSelector.swift
//  Molyseerr
//
//  Created by Claude on 30/12/2025.
//

import SwiftUI

/// Horizontal season selector inspired by Swiftfin
/// Displays a row of season buttons to switch between seasons
struct SeasonsSelector: View {
    let seasons: [Season]
    @Binding var selectedSeasonNumber: Int?

    @Namespace private var animation

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(seasons, id: \.seasonNumber) { season in
                        seasonButton(season: season)
                            .id(season.seasonNumber)
                    }
                }
                .padding(.horizontal, 90)
                .padding(.vertical, 20)
            }
            .onChange(of: selectedSeasonNumber) { _, newValue in
                if let newValue = newValue {
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func seasonButton(season: Season) -> some View {
        let isSelected = selectedSeasonNumber == season.seasonNumber

        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSeasonNumber = season.seasonNumber
            }
        } label: {
            Text(season.displayTitle)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.white : Color.white.opacity(0.2))
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.borderless)
    }
}
