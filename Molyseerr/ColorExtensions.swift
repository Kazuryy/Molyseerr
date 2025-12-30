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
        /// Primary indigo color (Seerr brand color - Tailwind indigo-500)
        static let indigo = Color(red: 0.388, green: 0.400, blue: 0.945) // #6366F1

        /// Primary color alias
        static let primary = indigo

        /// Indigo 600 (darker) for hover/pressed states (Tailwind indigo-600)
        static let indigoDark = Color(red: 0.310, green: 0.275, blue: 0.898) // #4F46E5

        /// Indigo 400 (lighter) for highlights (Tailwind indigo-400)
        static let indigoLight = Color(red: 0.514, green: 0.537, blue: 0.980) // #818CF8

        /// Input field background color
        static let inputBackground = Color(red: 0.14, green: 0.15, blue: 0.19)  // #24262F

        /// Background gradient dark
        static let backgroundDark = Color(red: 0.08, green: 0.09, blue: 0.13)  // #141621

        /// Background gradient darker
        static let backgroundDarker = Color(red: 0.05, green: 0.06, blue: 0.09)

        /// Card background color
        static let cardBackground = Color(red: 0.11, green: 0.12, blue: 0.16)  // #1c1e29

        /// Main app background color (Tailwind gray-900: #111827)
        static let background = Color(red: 17/255, green: 24/255, blue: 39/255)

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
        static let statusProcessing = indigo

        /// Available status (Tailwind green-500: #22C55E)
        static let statusAvailable = Color(red: 0.133, green: 0.773, blue: 0.369)

        /// Pending status (Tailwind yellow-500: #EAB308)
        static let statusPending = Color(red: 0.918, green: 0.702, blue: 0.031)

        /// Blacklisted/Deleted status (Tailwind red-500: #EF4444)
        static let statusError = Color(red: 0.937, green: 0.267, blue: 0.267)
    }
}
