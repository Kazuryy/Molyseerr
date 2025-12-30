//
//  CompanyCard.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI
import Kingfisher

/// Card component for displaying a studio or network logo
/// Pattern matches GenreCard with landscape 16:9 ratio
struct CompanyCard: View {
    let company: Company
    let onTap: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.6),
                                Color.black.opacity(0.8)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Logo
                if let logoURL = company.logoURL {
                    KFImage(logoURL)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(40)
                } else {
                    // Fallback text if no logo
                    Text(company.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(20)
                }

                // Focus overlay - lightens on focus
                if isFocused {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.15))
                }
            }
            .frame(width: 480, height: 270) // 16:9 landscape ratio
            .shadow(radius: isFocused ? 20 : 4)
            .scaleEffect(isFocused ? 1.08 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(.borderless)
        .focused($isFocused)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            CompanyCard(company: Company.studios[0]) {
                print("Tapped Disney")
            }

            CompanyCard(company: Company.networks[0]) {
                print("Tapped Netflix")
            }
        }
    }
}
