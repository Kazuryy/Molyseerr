//
//  ActionButtonStyle.swift
//  Molyseerr
//
//  Created by Claude on 30/12/2025.
//

import SwiftUI

/// Action button style for prominent buttons (Request, Watchlist, Trailer, etc.)
/// Uses native tvOS CardButtonStyle for automatic focus handling
/// Reference: docs/TVOS_FOCUS_GUIDE.md - Native focus prevents double zoom
struct ActionButtonStyle: PrimitiveButtonStyle {

    enum Variant {
        case primary    // Indigo background (Request button)
        case secondary  // Translucent white background (Watchlist, Trailer)
    }

    let variant: Variant

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

    @ViewBuilder
    private func contentView(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 30, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .cornerRadius(12)
    }

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.trigger()
        } label: {
            contentView(configuration: configuration)
        }
        .buttonStyle(.card)  // Native tvOS CardButtonStyle handles focus/zoom automatically
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
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
