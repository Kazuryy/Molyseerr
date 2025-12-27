//
//  ColorExtensions.swift
//  Molyseerr
//
//  Created by Assistant on 27/12/2025.
//

import SwiftUI

extension Color {
    /// Seerr brand colors and UI colors
    struct Seerr {
        /// Primary purple color (Seerr brand color)
        static let purple = Color(red: 0.482, green: 0.408, blue: 0.933) // #7B68EE

        /// Secondary purple (darker) for unfocused states
        static let purpleDark = Color(red: 0.43, green: 0.28, blue: 0.8)

        /// Input field background color
        static let inputBackground = Color(red: 0.14, green: 0.15, blue: 0.19)  // #24262F

        /// Background gradient dark
        static let backgroundDark = Color(red: 0.08, green: 0.09, blue: 0.13)  // #141621

        /// Background gradient darker
        static let backgroundDarker = Color(red: 0.05, green: 0.06, blue: 0.09)

        /// Card background color
        static let cardBackground = Color(red: 0.11, green: 0.12, blue: 0.16)  // #1c1e29

        /// Border color
        static let border = Color.white.opacity(0.15)

        /// Secondary text color
        static let secondaryText = Color(white: 0.7, opacity: 0.6)
    }
}
