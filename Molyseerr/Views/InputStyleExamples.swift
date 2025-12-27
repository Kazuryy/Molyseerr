//
//  InputStyleExamples.swift
//  Molyseerr
//
//  Created by Claude on 25/12/2025.
//

import SwiftUI

/// Seerr-style login page for tvOS
/// Recreates the Overseerr/Seerr login experience optimized for Apple TV
struct InputStyleExamples: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @FocusState private var focusedField: Field?
    @State private var isLoading: Bool = false
    
    enum Field: Hashable {
        case email, password, signIn
    }
    
    var body: some View {
        ZStack {
            // Seerr-style dark background with subtle gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.Seerr.backgroundDark,
                    Color.Seerr.backgroundDarker
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Login card container
                VStack(spacing: 32) {
                    // Logo and Title
                    VStack(spacing: 16) {
                        // Seerr logo placeholder (you can replace with actual logo)
                        Image(systemName: "tv.and.mediabox")
                            .font(.system(size: 80, weight: .thin))
                            .foregroundColor(.white)
                        
                        Text("Sign In")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 16)
                    
                    // Input fields
                    VStack(spacing: 20) {
                        // Email field
                        SeerrInputField(
                            placeholder: "Email",
                            text: $email,
                            icon: "envelope"
                        )

                        // Password field
                        SeerrSecureField(
                            placeholder: "Password",
                            text: $password,
                            icon: "lock"
                        )
                    }
                    
                    // Sign In Button
                    Button(action: {
                        isLoading = true
                        // Simulate login
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isLoading = false
                        }
                    }) {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            }
                            Text(isLoading ? "Signing In..." : "Sign In")
                                .font(.system(size: 28, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    focusedField == .signIn ? 
                                        Color.Seerr.purple :
                                        Color.Seerr.purpleDark
                                )
                        )
                        .scaleEffect(focusedField == .signIn ? 1.05 : 1.0)
                        .shadow(
                            color: focusedField == .signIn ? 
                                Color.Seerr.purple.opacity(0.5) : 
                                Color.clear,
                            radius: 20,
                            x: 0,
                            y: 10
                        )
                    }
                    .buttonStyle(.plain)
                    .focused($focusedField, equals: .signIn)
                    .padding(.top, 8)
                    .disabled(isLoading)
                }
                .frame(width: 600)
                .padding(50)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.Seerr.cardBackground)
                        .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 10)
                )
                
                Spacer()
                
                // Footer
                Text("Molyseerr for Apple TV")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Auto-focus email field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedField = .email
            }
        }
    }
}

// MARK: - Preview

#Preview {
    InputStyleExamples()
}
