//
//  StatusBadgeMini.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import SwiftUI

/// Mini status badge component for media cards
/// Displays availability status with color-coded circular icons
/// Source: webapp src/components/Common/StatusBadgeMini/index.tsx
struct StatusBadgeMini: View {
    let status: MediaStatus
    let shrink: Bool

    init(status: MediaStatus, shrink: Bool = false) {
        self.status = status
        self.shrink = shrink
    }

    var body: some View {
        Circle()
            .fill(statusColor)
            .opacity(0.8)
            .frame(width: shrink ? 32 : 36, height: shrink ? 32 : 36)
            .overlay(
                Image(systemName: statusIcon)
                    .font(.system(size: shrink ? 18 : 20, weight: .semibold))
                    .foregroundColor(.white)
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    // MARK: - Computed Properties

    private var statusColor: Color {
        switch status {
        case .processing:
            return Color.Seerr.statusProcessing
        case .available, .partiallyAvailable:
            return Color.Seerr.statusAvailable
        case .pending:
            return Color.Seerr.statusPending
        case .blacklisted, .deleted:
            return Color.Seerr.statusError
        case .unknown:
            return .gray
        }
    }

    private var statusIcon: String {
        switch status {
        case .processing:
            return "clock.fill"
        case .available:
            return "checkmark.circle.fill"
        case .pending:
            return "bell.fill"
        case .blacklisted:
            return "eye.slash.fill"
        case .partiallyAvailable:
            return "minus.circle.fill"
        case .deleted:
            return "trash.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            HStack(spacing: 20) {
                VStack {
                    StatusBadgeMini(status: .available)
                    Text("Available")
                        .font(.caption)
                        .foregroundColor(.white)
                }

                VStack {
                    StatusBadgeMini(status: .processing)
                    Text("Processing")
                        .font(.caption)
                        .foregroundColor(.white)
                }

                VStack {
                    StatusBadgeMini(status: .pending)
                    Text("Pending")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }

            HStack(spacing: 20) {
                VStack {
                    StatusBadgeMini(status: .partiallyAvailable)
                    Text("Partial")
                        .font(.caption)
                        .foregroundColor(.white)
                }

                VStack {
                    StatusBadgeMini(status: .blacklisted)
                    Text("Blacklisted")
                        .font(.caption)
                        .foregroundColor(.white)
                }

                VStack {
                    StatusBadgeMini(status: .deleted)
                    Text("Deleted")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }

            Text("Shrink mode:")
                .foregroundColor(.white)
                .padding(.top, 20)

            HStack(spacing: 20) {
                StatusBadgeMini(status: .available, shrink: true)
                StatusBadgeMini(status: .processing, shrink: true)
                StatusBadgeMini(status: .pending, shrink: true)
            }
        }
    }
}
