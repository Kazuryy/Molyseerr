//
//  FilterBar.swift
//  Molyseerr
//
//  Created by Claude on 28/12/2025.
//

import SwiftUI

/// Request filter options
enum RequestFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case pending = "pending"
    case approved = "approved"
    case available = "available"
    case processing = "processing"
    case failed = "failed"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .available: return "Available"
        case .processing: return "Processing"
        case .failed: return "Failed"
        }
    }
}

/// Horizontal filter bar for requests
struct FilterBar: View {
    @Binding var selectedFilter: RequestFilter
    @FocusState.Binding var focusedFilter: RequestFilter?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(RequestFilter.allCases) { filter in
                    FilterButton(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter,
                        isFocused: focusedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                    .focused($focusedFilter, equals: filter)
                }
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 12)
        }
        .scrollClipDisabled()
    }
}

/// Individual filter button
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(foregroundColor)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(backgroundColor)
                )
                .scaleEffect(isFocused ? 1.1 : 1.0)
                .shadow(radius: isFocused ? 12 : 4)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }

    private var foregroundColor: Color {
        if isSelected {
            return .black
        } else {
            return .white
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return .white
        } else if isFocused {
            return Color.white.opacity(0.3)
        } else {
            return Color.white.opacity(0.15)
        }
    }
}
