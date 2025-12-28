//
//  StatusBadge.swift
//  Molyseerr
//
//  Created by Claude on 28/12/2025.
//

import SwiftUI

/// Full status badge with text label
struct StatusBadge: View {
    let status: RequestStatus

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))

            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .textCase(.uppercase)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
        )
    }

    private var label: String {
        switch status {
        case .pending:
            return "Pending"
        case .approved:
            return "Approved"
        case .declined:
            return "Declined"
        case .failed:
            return "Failed"
        case .completed:
            return "Completed"
        }
    }

    private var icon: String {
        switch status {
        case .pending:
            return "clock.fill"
        case .approved:
            return "checkmark.circle.fill"
        case .declined:
            return "xmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        case .completed:
            return "checkmark.circle.fill"
        }
    }

    private var color: Color {
        switch status {
        case .pending:
            return Color(red: 234/255, green: 179/255, blue: 8/255) // Yellow
        case .approved:
            return Color(red: 59/255, green: 130/255, blue: 246/255) // Blue
        case .declined:
            return Color(red: 239/255, green: 68/255, blue: 68/255) // Red
        case .failed:
            return Color(red: 220/255, green: 38/255, blue: 38/255) // Dark Red
        case .completed:
            return Color(red: 34/255, green: 197/255, blue: 94/255) // Green
        }
    }
}

/// Media status badge (for available/pending media)
struct MediaStatusBadge: View {
    let status: MediaStatus

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))

            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .textCase(.uppercase)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
        )
    }

    private var label: String {
        switch status {
        case .unknown:
            return "Unknown"
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .partiallyAvailable:
            return "Partial"
        case .available:
            return "Available"
        case .blacklisted:
            return "Blacklisted"
        case .deleted:
            return "Deleted"
        }
    }

    private var icon: String {
        switch status {
        case .unknown:
            return "questionmark.circle.fill"
        case .pending:
            return "clock.fill"
        case .processing:
            return "arrow.down.circle.fill"
        case .partiallyAvailable:
            return "checkmark.circle.badge.questionmark.fill"
        case .available:
            return "checkmark.circle.fill"
        case .blacklisted:
            return "xmark.shield.fill"
        case .deleted:
            return "trash.fill"
        }
    }

    private var color: Color {
        switch status {
        case .unknown:
            return Color.gray
        case .pending:
            return Color(red: 234/255, green: 179/255, blue: 8/255) // Yellow
        case .processing:
            return Color(red: 99/255, green: 102/255, blue: 241/255) // Indigo
        case .partiallyAvailable:
            return Color(red: 168/255, green: 85/255, blue: 247/255) // Purple
        case .available:
            return Color(red: 34/255, green: 197/255, blue: 94/255) // Green
        case .blacklisted:
            return Color(red: 220/255, green: 38/255, blue: 38/255) // Dark Red
        case .deleted:
            return Color(red: 107/255, green: 114/255, blue: 128/255) // Gray
        }
    }
}
