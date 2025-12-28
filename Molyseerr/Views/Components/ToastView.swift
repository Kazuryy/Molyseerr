//
//  ToastView.swift
//  Molyseerr
//
//  Created by Claude on 28/12/2025.
//

import SwiftUI

/// Toast notification types
enum ToastType {
    case success
    case error
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        }
    }
}

/// Toast notification view for user feedback
struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isPresented: Bool

    var body: some View {
        if isPresented {
            HStack(spacing: 16) {
                Image(systemName: type.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)

                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(type.color.opacity(0.95))
                    .shadow(radius: 20)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                // Auto-dismiss after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        isPresented = false
                    }
                }
            }
        }
    }
}

/// Toast modifier for easy usage
struct ToastModifier: ViewModifier {
    @Binding var toast: ToastConfig?

    func body(content: Content) -> some View {
        ZStack {
            content

            if let toast = toast {
                VStack {
                    ToastView(
                        message: toast.message,
                        type: toast.type,
                        isPresented: Binding(
                            get: { self.toast != nil },
                            set: { if !$0 { self.toast = nil } }
                        )
                    )
                    .padding(.top, 60)

                    Spacer()
                }
                .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: toast != nil)
    }
}

/// Toast configuration
struct ToastConfig: Equatable {
    let message: String
    let type: ToastType

    static func success(_ message: String) -> ToastConfig {
        ToastConfig(message: message, type: .success)
    }

    static func error(_ message: String) -> ToastConfig {
        ToastConfig(message: message, type: .error)
    }

    static func info(_ message: String) -> ToastConfig {
        ToastConfig(message: message, type: .info)
    }
}

/// View extension for easy toast usage
extension View {
    func toast(_ toast: Binding<ToastConfig?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
