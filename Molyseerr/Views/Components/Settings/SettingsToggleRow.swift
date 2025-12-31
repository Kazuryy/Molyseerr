//
//  SettingsToggleRow.swift
//  Molyseerr
//
//  Created by Claude on 31/12/2025.
//

import SwiftUI

/// Settings toggle row component for tvOS
/// Displays a setting with toggle switch
struct SettingsToggleRow: View {
    let title: String
    let description: String?
    @Binding var isOn: Bool
    let icon: String?

    init(
        title: String,
        description: String? = nil,
        isOn: Binding<Bool>,
        icon: String? = nil
    ) {
        self.title = title
        self.description = description
        self._isOn = isOn
        self.icon = icon
    }

    var body: some View {
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

            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        SettingsToggleRow(
            title: "Auto-Request Movies",
            description: "Automatically request movies added to watchlist",
            isOn: .constant(true),
            icon: "film"
        )

        SettingsToggleRow(
            title: "Auto-Request TV Shows",
            description: "Automatically request TV shows added to watchlist",
            isOn: .constant(false),
            icon: "tv"
        )
    }
    .padding()
    .background(Color.black)
}
