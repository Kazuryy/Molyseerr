//
//  ActionButtonStyle.swift
//  Molyseerr
//
//  Created by Claude on 30/12/2025.
//

import SwiftUI

/// Action button style for prominent buttons (Request, Watchlist, Trailer, etc.)
/// Inspired by Swiftfin's button handling with Molyseerr colors
struct ActionButtonStyle: PrimitiveButtonStyle {

    enum Variant {
        case primary    // Indigo background (Request button)
        case secondary  // Translucent white background (Watchlist, Trailer)
    }

    let variant: Variant

    @FocusState
    private var isFocused: Bool

    init(variant: Variant = .secondary) {
        self.variant = variant
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return Color.Seerr.indigo
        case .secondary:
            return Color.white.opacity(0.2)
        }
    }

    private var focusedBackgroundColor: Color {
        switch variant {
        case .primary:
            return Color.Seerr.indigo.opacity(0.9)
        case .secondary:
            return Color.white.opacity(0.3)
        }
    }

    @ViewBuilder
    private func contentView(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 30, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFocused ? focusedBackgroundColor : backgroundColor)
            )
            .scaleEffect(isFocused ? 1.08 : 1.0)
            .shadow(
                color: isFocused ? (variant == .primary ? Color.Seerr.indigo.opacity(0.6) : Color.white.opacity(0.3)) : .black.opacity(0.4),
                radius: isFocused ? 25 : 15
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
    }

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.trigger()
        } label: {
            contentView(configuration: configuration)
        }
        .buttonStyle(.borderless)
        .focused($isFocused)
    }
}

extension PrimitiveButtonStyle where Self == ActionButtonStyle {
    static var actionPrimary: ActionButtonStyle {
        ActionButtonStyle(variant: .primary)
    }

    static var actionSecondary: ActionButtonStyle {
        ActionButtonStyle(variant: .secondary)
    }
}
