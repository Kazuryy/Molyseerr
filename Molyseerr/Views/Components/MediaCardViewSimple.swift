//
//  MediaCardViewSimple.swift
//  Molyseerr
//
//  Simplified MediaCardView without SwiftUI focus (for use in UICollectionView)
//  Focus effects are handled by the UICollectionViewCell itself
//

import SwiftUI
import Kingfisher

/// Simplified media card for use in PerformantHStack (UICollectionView)
/// Focus effects are handled by UIKit, not SwiftUI
struct MediaCardViewSimple: View {
    let item: MediaResult

    // MARK: - Constants
    private let cardWidth: CGFloat = 250
    private let cardHeight: CGFloat = 375  // 2:3 ratio
    private let cornerRadius: CGFloat = 8

    var body: some View {
        posterView
    }

    // MARK: - Subviews

    private var posterView: some View {
        ZStack {
            // Poster image using Kingfisher
            if let posterURL = TMDBImageHelper.posterURL(path: item.posterPath) {
                KFImage(posterURL)
                    .placeholder {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: cardWidth, height: cardHeight)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(Color.gray.opacity(0.3))
                                    .shimmer()
                            )
                    }
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: cardWidth * 1.5, height: cardHeight * 1.5)))
                    .cacheOriginalImage()
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()
                    .cornerRadius(cornerRadius)
            } else {
                // Fallback if no poster available
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: item.mediaType == .movie ? "film" : "tv")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.3))
                    )
            }

            // Top badges overlay
            VStack {
                HStack(alignment: .top) {
                    // Media type badge (top-left)
                    mediaTypeIcon

                    Spacer()

                    // Status badge (top-right)
                    if let mediaInfo = item.mediaInfo,
                       mediaInfo.status != .unknown {
                        StatusBadgeMini(status: mediaInfo.status, shrink: true)
                    }
                }
                .padding(12)
                .drawingGroup()
                Spacer()
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }

    private var mediaTypeIcon: some View {
        Text(item.mediaType == .movie ? "MOVIE" : "SERIES")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(item.mediaType == .movie ? Color.Seerr.movieBadge : Color.Seerr.seriesBadge)
                    .opacity(0.8)
            )
    }
}
