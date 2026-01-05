//
//  SkeletonCardView.swift
//  Molyseerr
//
//  Created by Claude on 03/01/2026.
//

import SwiftUI

/// Skeleton placeholder for MediaCardView during loading
/// Matches the exact dimensions of MediaCardView for seamless transition
struct SkeletonCardView: View {
    private let cardWidth: CGFloat = 250
    private let cardHeight: CGFloat = 375
    private let cornerRadius: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.2))
            .frame(width: cardWidth, height: cardHeight)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.3))
                    .shimmer()
            )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        HStack(spacing: 40) {
            SkeletonCardView()
            SkeletonCardView()
            SkeletonCardView()
        }
    }
}
