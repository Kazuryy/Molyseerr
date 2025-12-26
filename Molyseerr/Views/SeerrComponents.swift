//
//  SeerrComponents.swift
//  Molyseerr
//
//  Created by Claude on 26/12/2025.
//

import SwiftUI

// MARK: - Seerr-style Input Components

/// Reusable Seerr-style text input field
struct SeerrInputField: View {
    let placeholder: String
    @Binding var text: String
    let isFocused: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 30)
            
            // Text field
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(.white)
                .tint(Color(red: 0.5, green: 0.35, blue: 0.9))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.14, green: 0.15, blue: 0.19))  // Seerr input bg #24262F
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isFocused ? 
                                Color(red: 0.5, green: 0.35, blue: 0.9) :  // Purple when focused
                                Color.white.opacity(0.1),
                            lineWidth: isFocused ? 3 : 1
                        )
                )
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}

/// Reusable Seerr-style secure input field
struct SeerrSecureField: View {
    let placeholder: String
    @Binding var text: String
    let isFocused: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 30)
            
            // Secure field
            SecureField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(.white)
                .tint(Color(red: 0.5, green: 0.35, blue: 0.9))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.14, green: 0.15, blue: 0.19))  // Seerr input bg #24262F
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isFocused ? 
                                Color(red: 0.5, green: 0.35, blue: 0.9) :  // Purple when focused
                                Color.white.opacity(0.1),
                            lineWidth: isFocused ? 3 : 1
                        )
                )
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}

// MARK: - Seerr Colors Extension

extension Color {
    /// Seerr brand colors
    struct Seerr {
        /// Primary purple color for buttons and accents
        static let purple = Color(red: 0.5, green: 0.35, blue: 0.9)
        
        /// Secondary purple (darker) for unfocused states
        static let purpleDark = Color(red: 0.43, green: 0.28, blue: 0.8)
        
        /// Background gradient dark
        static let backgroundDark = Color(red: 0.08, green: 0.09, blue: 0.13)  // #141621
        
        /// Background gradient darker
        static let backgroundDarker = Color(red: 0.05, green: 0.06, blue: 0.09)
        
        /// Card background
        static let cardBackground = Color(red: 0.11, green: 0.12, blue: 0.16)  // #1c1e29
        
        /// Input field background
        static let inputBackground = Color(red: 0.14, green: 0.15, blue: 0.19)  // #24262F
    }
}
