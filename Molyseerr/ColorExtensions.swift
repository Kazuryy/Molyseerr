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
        
        /// Input field background color
        static let inputBackground = Color(white: 1.0, opacity: 0.1)
        
        /// Darker background color
        static let darkBackground = Color(red: 0.067, green: 0.067, blue: 0.078) // #111114
        
        /// Card background color
        static let cardBackground = Color(white: 0.15, opacity: 0.3)
        
        /// Border color
        static let border = Color.white.opacity(0.15)
        
        /// Secondary text color
        static let secondaryText = Color(white: 0.7, opacity: 0.6)
    }
}
