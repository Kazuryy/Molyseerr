//
//  MediaStatus+Helpers.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import SwiftUI

/// Extensions for MediaStatus to provide UI helpers
/// Based on TVOS_ARCH_SPEC.md Section 2.1 (Status Badge Mapping)
extension MediaStatus {
    /// Display text for status
    var displayText: String {
        switch self {
        case .unknown:
            return ""
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .partiallyAvailable:
            return "Partially Available"
        case .available:
            return "Available"
        case .blacklisted:
            return "Blacklisted"
        case .deleted:
            return "Deleted"
        }
    }

    /// Badge color for status (from TVOS_ARCH_SPEC.md Appendix A)
    var badgeColor: Color {
        switch self {
        case .unknown:
            return .clear
        case .pending:
            return Color(hex: "eab308")  // Yellow 500
        case .processing:
            return Color(hex: "6366f1")  // Indigo 500
        case .partiallyAvailable, .available:
            return Color(hex: "22c55e")  // Green 500
        case .blacklisted, .deleted:
            return Color(hex: "ef4444")  // Red 500
        }
    }

    /// Whether to show this status badge
    var shouldShowBadge: Bool {
        return self != .unknown
    }
}

/// Color extension for hex initialization
/// Source: TVOS_ARCH_SPEC.md Appendix A
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

/// Color palette from design system
/// Source: TVOS_ARCH_SPEC.md Appendix A
extension Color {
    // Primary
    static let seerrIndigo500 = Color(hex: "6366f1")
    static let seerrIndigo600 = Color(hex: "4f46e5")

    // Success
    static let seerrGreen500 = Color(hex: "22c55e")

    // Warning
    static let seerrYellow500 = Color(hex: "eab308")

    // Danger
    static let seerrRed500 = Color(hex: "ef4444")
    static let seerrRed600 = Color(hex: "dc2626")

    // Backgrounds
    static let seerrGray900 = Color(hex: "111827")
    static let seerrGray800 = Color(hex: "1f2937")
    static let seerrGray700 = Color(hex: "374151")
    static let seerrGray600 = Color(hex: "4b5563")
    static let seerrGray500 = Color(hex: "6b7280")
    static let seerrGray400 = Color(hex: "9ca3af")
    static let seerrGray300 = Color(hex: "d1d5db")

    // Media Types
    static let seerrBlue500 = Color(hex: "3b82f6")
    static let seerrPurple600 = Color(hex: "9333ea")
}
