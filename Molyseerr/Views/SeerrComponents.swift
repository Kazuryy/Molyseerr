//
//  SeerrComponents.swift
//  Molyseerr
//
//  Created by Claude on 26/12/2025.
//

import SwiftUI
import UIKit

// MARK: - Seerr-style Input Components (Using UITextField for tvOS)

/// Reusable Seerr-style text input field with UITextField
struct SeerrInputField: View {
    let placeholder: String
    @Binding var text: String
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

// MARK: - Previews

struct SeerrComponents_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            InputFieldNormalPreview()
            InputFieldWithTextPreview()
            SecureFieldPreview()
            LoginFormPreview()
            ColorPalettePreview()
        }
    }
}

private struct InputFieldNormalPreview: View {
    @State private var text = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Input Field Normal")
                .font(.headline)
                .foregroundColor(.white)
            
            SeerrInputField(
                placeholder: "Server URL",
                text: $text,
                icon: "server.rack"
            )
            
            Text("Text: '\(text)'")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.Seerr.backgroundDark, Color.Seerr.backgroundDarker],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct InputFieldWithTextPreview: View {
    @State private var text = "https://seerr.example.com"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Input Field avec du texte")
                .font(.headline)
                .foregroundColor(.white)
            
            SeerrInputField(
                placeholder: "Server URL",
                text: $text,
                icon: "server.rack"
            )
            
            Button("Effacer") {
                text = ""
            }
            .foregroundColor(.white)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.Seerr.backgroundDark, Color.Seerr.backgroundDarker],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct SecureFieldPreview: View {
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Secure Field")
                .font(.headline)
                .foregroundColor(.white)
            
            SeerrSecureField(
                placeholder: "API Key",
                text: $password,
                icon: "key.fill"
            )
            
            Text("Password: '\(password)'")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.Seerr.backgroundDark, Color.Seerr.backgroundDarker],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct LoginFormPreview: View {
    @State private var serverUrl = ""
    @State private var apiKey = ""
    @State private var email = ""
    
    var body: some View {
        VStack(spacing: 30) {
            // Logo/Title
            VStack(spacing: 12) {
                Image(systemName: "film.stack")
                    .font(.system(size: 80))
                    .foregroundColor(Color.Seerr.purple)
                
                Text("Molyseerr")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Configuration")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.bottom, 20)
            
            // Input fields
            VStack(spacing: 20) {
                SeerrInputField(
                    placeholder: "Server URL",
                    text: $serverUrl,
                    icon: "server.rack"
                )
                
                SeerrInputField(
                    placeholder: "Email",
                    text: $email,
                    icon: "envelope.fill"
                )
                
                SeerrSecureField(
                    placeholder: "API Key",
                    text: $apiKey,
                    icon: "key.fill"
                )
            }
            
            // Button example
            Button(action: {}) {
                HStack {
                    Text("Se connecter")
                        .font(.system(size: 32, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 28))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(Color.Seerr.purple)
                .cornerRadius(8)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.Seerr.backgroundDark, Color.Seerr.backgroundDarker],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct ColorPalettePreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Seerr Color Palette")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                VStack(spacing: 20) {
                    ColorSwatch(name: "Purple", color: Color.Seerr.purple)
                    ColorSwatch(name: "Purple Dark", color: Color.Seerr.purpleDark)
                    ColorSwatch(name: "Background Dark", color: Color.Seerr.backgroundDark)
                    ColorSwatch(name: "Background Darker", color: Color.Seerr.backgroundDarker)
                    ColorSwatch(name: "Card Background", color: Color.Seerr.cardBackground)
                    ColorSwatch(name: "Input Background", color: Color.Seerr.inputBackground)
                }
                .padding(40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// Helper view for color palette preview
private struct ColorSwatch: View {
    let name: String
    let color: Color
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 120, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            Text(name)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}



