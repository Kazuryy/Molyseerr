//
//  AnimatedBackgroundView.swift
//  Molyseerr
//
//  Created by Claude on 25/12/2025.
//

import SwiftUI
import Kingfisher

/// Animated background view that cycles through backdrop images
/// Inspired by Seerr's ImageFader component with TMDB backdrops
struct AnimatedBackgroundView: View {

    let images: [String]
    let rotationSpeed: TimeInterval

    @State private var activeIndex: Int = 0
    @State private var timer: Timer?

    init(images: [String] = [], rotationSpeed: TimeInterval = 6.0) {
        self.images = images
        self.rotationSpeed = rotationSpeed
    }

    var body: some View {
        ZStack {
            // Background images with fade transition
            ForEach(Array(images.enumerated()), id: \.offset) { index, imagePath in
                if let imageURL = TMDBImageHelper.backdropURL(path: imagePath) {
                    KFImage(imageURL)
                        .placeholder {
                            Color(red: 0.1, green: 0.15, blue: 0.3)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .opacity(activeIndex == index ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.3), value: activeIndex)
                }
            }

            // Dark gradient overlay (Seerr style)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 45/255, green: 55/255, blue: 72/255).opacity(0.47),
                    Color(red: 26/255, green: 32/255, blue: 46/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .onAppear {
            startRotation()
        }
        .onDisappear {
            stopRotation()
        }
    }

    // MARK: - Private Methods

    private func startRotation() {
        guard !images.isEmpty else { return }

        timer = Timer.scheduledTimer(withTimeInterval: rotationSpeed, repeats: true) { _ in
            activeIndex = (activeIndex + 1) % images.count
        }
    }

    private func stopRotation() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Preview

#Preview {
    AnimatedBackgroundView(images: [
        "/path1.jpg",
        "/path2.jpg",
        "/path3.jpg"
    ])
}
