//
//  CardButtonStyle.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import SwiftUI

/// Swiftfin-style card button for tvOS
/// Uses native .card button style + .hoverEffect(.highlight) for clear focus indication
extension View {
    /// Apply Swiftfin-style focus effect to cards
    func cardFocus() -> some View {
        self
            .hoverEffect(.highlight)
            .shadow(radius: 4, y: 2)
    }
}
