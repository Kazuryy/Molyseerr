//
//  SettingsPickerRow.swift
//  Molyseerr
//
//  Created by Claude on 31/12/2025.
//

import SwiftUI

/// Settings picker row component for tvOS
/// Displays a setting with navigation to picker view
struct SettingsPickerRow: View {
    let title: String
    let description: String?
    let currentValue: String
    let icon: String?
    let action: () -> Void

    @FocusState private var isFocused: Bool

    init(
        title: String,
        description: String? = nil,
        currentValue: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.currentValue = currentValue
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Icon (optional)
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(.Seerr.primary)
                        .frame(width: 40)
                }

                // Title and description
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)

                    if let description = description {
                        Text(description)
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Current value
                Text(currentValue)
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isFocused ? 0.2 : 0.1))
                    .background(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

#Preview {
    VStack(spacing: 20) {
        SettingsPickerRow(
            title: "Display Language",
            description: "Language for the app interface",
            currentValue: "English",
            icon: "globe",
            action: {}
        )

        SettingsPickerRow(
            title: "Discover Region",
            description: "Filter content by regional availability",
            currentValue: "United States",
            icon: "map",
            action: {}
        )
    }
    .padding()
    .background(Color.black)
}
