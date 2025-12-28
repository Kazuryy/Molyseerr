//
//  FilterBar.swift
//  Molyseerr
//
//  Created by Claude on 28/12/2025.
//

import SwiftUI

/// Request filter options
/// Maps to Seerr API filter parameter (see server/routes/request.ts:45-75)
enum RequestFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case pending = "pending"
    case processing = "processing"  // Maps to APPROVED status
    case available = "available"    // APPROVED + media AVAILABLE
    case unavailable = "unavailable" // PENDING or APPROVED + media not AVAILABLE
    case failed = "failed"
    case completed = "completed"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .available: return "Available"
        case .unavailable: return "Unavailable"
        case .failed: return "Failed"
        case .completed: return "Completed"
        }
    }
}

/// Horizontal filter bar for requests
struct FilterBar: View {
    @Binding var selectedFilter: RequestFilter
    @FocusState.Binding var focusedFilter: RequestFilter?
    var onFilterSelected: ((RequestFilter) -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(RequestFilter.allCases) { filter in
                    FilterButton(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter,
                        isFocused: focusedFilter == filter
                    ) {
                        onFilterSelected?(filter)
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
        .buttonStyle(.card)
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
