//
//  PrimaryButtonStyle.swift
//  Molyseerr
//
//  Created by Claude on 26/12/2025.
//

import SwiftUI

/// Primary button style following Swiftfin's design patterns
/// Source: Swiftfin /Shared/Components/PrimaryButtonStyle.swift
struct PrimaryButtonStyle: PrimitiveButtonStyle {

    let backgroundColor: Color

    @Environment(\.isEnabled)
    private var isEnabled

    @FocusState
    private var isFocused: Bool

    init(backgroundColor: Color = Color.Seerr.indigo) {
        self.backgroundColor = backgroundColor
    }

    private func primaryStyle(configuration: Configuration) -> some ShapeStyle {
        if configuration.role == .destructive || configuration.role == .cancel {
            if isFocused {
                return AnyShapeStyle(HierarchicalShapeStyle.primary)
            } else {
                return AnyShapeStyle(Color.red)
            }
        } else {
            return AnyShapeStyle(HierarchicalShapeStyle.primary)
        }
    }

    private func secondaryStyle(configuration: Configuration) -> some ShapeStyle {
        if configuration.role == .destructive || configuration.role == .cancel {
            return AnyShapeStyle(
                Color.red.opacity(isFocused ? 1.0 : 0.15)
            )
        } else {
            // Use custom backgroundColor instead of hierarchical secondary
            if isEnabled {
                return AnyShapeStyle(backgroundColor)
            } else {
                return AnyShapeStyle(Color.gray)
            }
        }
    }

    @ViewBuilder
    private func contentView(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(secondaryStyle(configuration: configuration))
                .brightness(isFocused ? 0.15 : 0.0)
                .frame(idealHeight: 44)

            configuration.label
                .foregroundStyle(primaryStyle(configuration: configuration))
        }
        .font(.body)
        .fontWeight(.semibold)
    }

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.trigger()
        } label: {
            contentView(configuration: configuration)
        }
        .listRowInsets(EdgeInsets())
        .buttonStyle(.borderless)
        .focused($isFocused)
    }
}

extension PrimitiveButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle {
        PrimaryButtonStyle()
    }

    static func primary(backgroundColor: Color) -> PrimaryButtonStyle {
        PrimaryButtonStyle(backgroundColor: backgroundColor)
    }
}
