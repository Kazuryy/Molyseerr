//
//  ShimmerEffect.swift
//  Molyseerr
//
//  Created by Claude on 03/01/2026.
//

import SwiftUI

/// Shimmer effect for skeleton loading states
/// Creates an animated gradient that moves across the view
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.15),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 500
                }
            }
    }
}

extension View {
    /// Apply shimmer effect to any view
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}
