//
//  GenreCard.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import SwiftUI

/// Genre card component matching Seerr web app design
/// Displays a genre with backdrop image and duotone gradient overlay
/// Follows FOCUS_SYSTEM.md guidelines for tvOS focus effects
struct GenreCard: View {
    let genre: Genre

    @FocusState private var isFocused: Bool

    // MARK: - Constants
    private let cardWidth: CGFloat = 480  // Optimized for Apple TV
    private let cardHeight: CGFloat = 270 // 16:9 aspect ratio feel
    private let focusScale: CGFloat = 1.08 // 8% zoom (similar to TodayReleaseCard)

    var body: some View {
        cardContent
            .focused($isFocused)                                  // Track focus state
            .scaleEffect(isFocused ? focusScale : 1.0)           // Zoom entire card
            .shadow(radius: isFocused ? 20 : 4, y: isFocused ? 10 : 2)  // Dynamic shadow
            .animation(.easeInOut(duration: 0.15), value: isFocused)    // Quick animation
    }

    // MARK: - Card Content

    private var cardContent: some View {
        ZStack {
            // Background image
            if let backdropPath = genre.backdrops?.first,
               !backdropPath.isEmpty {
                AsyncImage(url: TMDBImageHelper.imageURL(path: backdropPath, size: .backdropLarge)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_), .empty:
                        // Fallback gradient if image fails to load
                        gradientBackground
                    @unknown default:
                        gradientBackground
                    }
                }
            } else {
                // Fallback gradient if no backdrop
                gradientBackground
            }

            // Duotone gradient overlay (lightens on focus)
            LinearGradient(
                gradient: Gradient(colors: [
                    genreColors.0.opacity(isFocused ? 0.3 : 0.5),
                    genreColors.1.opacity(isFocused ? 0.4 : 0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Dark overlay (lightens on focus)
            Color.black.opacity(isFocused ? 0.1 : 0.3)

            // Genre name
            Text(genre.name)
                .font(.system(size: 44, weight: .bold, design: .default))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
                .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 4)
        }
        .frame(width: cardWidth, height: cardHeight)
        .cornerRadius(12)
    }

    // MARK: - Computed Properties

    /// Get duotone colors for this genre
    private var genreColors: (Color, Color) {
        GenreColorHelper.getColors(for: genre.id)
    }

    /// Fallback gradient background
    private var gradientBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [genreColors.0, genreColors.1]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

}

#Preview {
    let sampleGenre = Genre(
        id: 28,
        name: "Action",
        backdrops: ["/path/to/backdrop.jpg"]
    )

    return GenreCard(genre: sampleGenre)
        .preferredColorScheme(.dark)
}
