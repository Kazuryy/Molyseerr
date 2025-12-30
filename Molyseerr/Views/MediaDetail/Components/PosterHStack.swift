//
//  PosterHStack.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI
import Kingfisher

/// Horizontal scrolling stack of posters (for cast, similar items, recommendations)
/// Inspired by Swiftfin's PosterHStack with Seerr styling
struct PosterHStack<Item: Identifiable>: View {
    let title: String
    let items: [Item]
    let posterPath: (Item) -> String?
    let onTap: (Item) -> Void

    // Optional overlay content (e.g., ratings, progress)
    var overlay: ((Item) -> AnyView)?

    private let posterWidth: CGFloat = 200
    private let posterHeight: CGFloat = 300
    private let spacing: CGFloat = 24

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section title
            Text(title)
                .font(.system(size: 38, weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, 90)

            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: spacing) {
                    ForEach(items) { item in
                        Button {
                            onTap(item)
                        } label: {
                            PosterCard(
                                posterPath: posterPath(item),
                                width: posterWidth,
                                height: posterHeight,
                                overlay: overlay?(item)
                            )
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal, 90)
            }
        }
    }
}

/// Individual poster card with optional overlay
struct PosterCard: View {
    let posterPath: String?
    let width: CGFloat
    let height: CGFloat
    var overlay: AnyView?

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Poster image
            if let posterURL = TMDBImageHelper.posterURL(path: posterPath) {
                KFImage(posterURL)
                    .placeholder {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .scaleEffect(1.5)
                            )
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .cornerRadius(12)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: width, height: height)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.3))
                    )
            }

            // Optional overlay content
            if let overlay = overlay {
                overlay
            }
        }
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .shadow(color: .black.opacity(isFocused ? 0.6 : 0.3), radius: isFocused ? 30 : 15)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Cast Poster Variant

/// Specialized poster card for cast members with circular profile image
struct CastPosterCard: View {
    let cast: Cast
    var isFocused: Bool = false

    private let baseSize: CGFloat = 200
    private var currentSize: CGFloat {
        isFocused ? baseSize * 1.08 : baseSize
    }

    var body: some View {
        VStack(spacing: 16) {
            // Profile image (circular) - image stays at fixed size
            if let profileURL = TMDBImageHelper.imageURL(path: cast.profilePath, size: .posterMedium) {
                KFImage(profileURL)
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: baseSize, height: baseSize)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white.opacity(0.3))
                            )
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: baseSize, height: baseSize)
                    .clipShape(Circle())
                    .drawingGroup() // Rasterize to prevent content scaling
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: baseSize, height: baseSize)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                    )
            }

            // Name
            Text(cast.name)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: baseSize)

            // Character/Role
            if let character = cast.character {
                Text(character)
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: baseSize)
            }
        }
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}
