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

        // MARK: - Media Type Badge Colors (matching webapp Seerr)

        /// Movie badge background color (Tailwind blue-600: #2563EB)
        static let movieBadge = Color(red: 0.145, green: 0.388, blue: 0.922)

        /// Movie badge border color (Tailwind blue-500: #3B82F6)
        static let movieBadgeBorder = Color(red: 0.231, green: 0.510, blue: 0.965)

        /// Series badge background color (Tailwind purple-600: #9333EA)
        static let seriesBadge = Color(red: 0.576, green: 0.200, blue: 0.918)

        // MARK: - Media Status Badge Colors (matching webapp Seerr)

        /// Processing status (Tailwind indigo-500: #6366F1)
        static let statusProcessing = Color(red: 0.388, green: 0.400, blue: 0.945)

        /// Available status (Tailwind green-500: #22C55E)
        static let statusAvailable = Color(red: 0.133, green: 0.773, blue: 0.369)

        /// Pending status (Tailwind yellow-500: #EAB308)
        static let statusPending = Color(red: 0.918, green: 0.702, blue: 0.031)

        /// Blacklisted/Deleted status (Tailwind red-500: #EF4444)
        static let statusError = Color(red: 0.937, green: 0.267, blue: 0.267)
    }
}
