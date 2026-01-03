//
//  SettingsSection.swift
//  Molyseerr
//
//  Created by Claude on 31/12/2025.
//

import SwiftUI

/// Settings section header component for tvOS
/// Groups related settings together
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String?
    @ViewBuilder let content: Content

    init(
        title: String,
        icon: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.Seerr.primary)
                }

                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 50)
            .padding(.top, 20)

            // Section content
            VStack(spacing: 16) {
                content
            }
            .padding(.horizontal, 50)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 40) {
            SettingsSection(title: "Display Preferences", icon: "display") {
                SettingsPickerRow(
                    title: "Language",
                    currentValue: "English",
                    action: {}
                )

                SettingsPickerRow(
                    title: "Region",
                    currentValue: "United States",
                    action: {}
                )
            }

            SettingsSection(title: "Auto-Request", icon: "arrow.down.circle") {
                SettingsToggleRow(
                    title: "Movies",
                    isOn: .constant(true)
                )

                SettingsToggleRow(
                    title: "TV Shows",
                    isOn: .constant(false)
                )
            }
        }
    }
    .background(Color.black)
}
