//
//  FocusHelper.swift
//  Molyseerr
//
//  Created by Claude on 02/01/2026.
//

import SwiftUI

/// ViewModifier to improve tvOS focus navigation
/// Wraps content in a focus section for better navigation between sections
struct SmartFocusSection: ViewModifier {
    func body(content: Content) -> some View {
        if #available(tvOS 16.0, *) {
            content
                .focusSection()
        } else {
            content
        }
    }
}

extension View {
    /// Wraps the view in a focus section for improved tvOS navigation
    /// This allows tvOS to navigate between sections more intelligently
    func smartFocusSection() -> some View {
        modifier(SmartFocusSection())
    }
}
