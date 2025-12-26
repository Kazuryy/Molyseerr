//
//  SeerrComponents.swift
//  Molyseerr
//
//  Created by Claude on 26/12/2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Seerr-style Input Components (Using UITextField for tvOS)

/// Reusable Seerr-style text input field with UITextField
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
            
            // UITextField wrapper
            CustomTextFieldWrapper(
                text: $text,
                placeholder: placeholder,
                isSecure: false
            )
            .frame(height: 40)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 15)
        .frame(height: 70)
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.Seerr.inputBackground)
                
                // Static border
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 2)
            }
        )
    }
}

/// Reusable Seerr-style secure field with UITextField
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
            
            // UITextField wrapper (secure)
            CustomTextFieldWrapper(
                text: $text,
                placeholder: placeholder,
                isSecure: true
            )
            .frame(height: 40)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 15)
        .frame(height: 70)
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.Seerr.inputBackground)
                
                // Static border
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 2)
            }
        )
    }
}

// MARK: - UITextField Wrapper for tvOS

#if canImport(UIKit)
struct CustomTextFieldWrapper: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let isSecure: Bool
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        
        // Style configuration
        textField.placeholder = placeholder
        textField.textColor = UIColor.white
        textField.font = UIFont.systemFont(ofSize: 28, weight: .regular)
        textField.backgroundColor = UIColor.clear
        textField.borderStyle = .none
        textField.isSecureTextEntry = isSecure
        
        // Placeholder styling
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.4),
            .font: UIFont.systemFont(ofSize: 28, weight: .regular)
        ]
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: attributes
        )
        
        // Tint color for cursor (Seerr purple)
        textField.tintColor = UIColor(red: 0.5, green: 0.35, blue: 0.9, alpha: 1.0)
        
        // Delegate for text changes
        textField.delegate = context.coordinator
        
        // Add target for text changes
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textFieldDidChange(_:)),
            for: .editingChanged
        )
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        @objc func textFieldDidChange(_ textField: UITextField) {
            text = textField.text ?? ""
        }
    }
}
#endif

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
