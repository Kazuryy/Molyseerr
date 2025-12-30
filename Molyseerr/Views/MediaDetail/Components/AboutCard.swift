//
//  AboutCard.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI
import Kingfisher

/// Card component for "About" section information
/// Inspired by Swiftfin's AboutView cards with Seerr styling
struct AboutCard: View {
    let title: String
    var subtitle: String? = nil
    let content: AnyView

    @FocusState private var isFocused: Bool

    private let cardWidth: CGFloat = 700
    private let cardHeight: CGFloat = 405

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            // Content
            content
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Seerr.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFocused ? Color.Seerr.indigo : Color.Seerr.border, lineWidth: isFocused ? 3 : 1)
                )
        )
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .shadow(color: isFocused ? Color.Seerr.indigo.opacity(0.5) : .black.opacity(0.3), radius: isFocused ? 25 : 15)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Specialized About Cards

/// Overview card with synopsis text
struct OverviewCard: View {
    let overview: String

    var body: some View {
        AboutCard(
            title: "Overview",
            content: AnyView(
                ScrollView {
                    Text(overview)
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            )
        )
    }
}

/// Ratings card with TMDB, IMDb, Rotten Tomatoes scores
struct RatingsCard: View {
    var tmdbRating: Double?
    var imdbRating: String?
    var rtCriticsRating: Int?
    var rtAudienceRating: Int?

    var body: some View {
        AboutCard(
            title: "Ratings",
            content: AnyView(
                VStack(alignment: .leading, spacing: 20) {
                    // TMDB Rating
                    if let tmdb = tmdbRating {
                        RatingRow(
                            icon: "star.fill",
                            iconColor: .yellow,
                            label: "TMDB",
                            value: String(format: "%.1f/10", tmdb)
                        )
                    }

                    // IMDb Rating
                    if let imdb = imdbRating {
                        RatingRow(
                            icon: "star.fill",
                            iconColor: Color(red: 0.95, green: 0.77, blue: 0.18),
                            label: "IMDb",
                            value: "\(imdb)/10"
                        )
                    }

                    // Rotten Tomatoes Critics
                    if let critics = rtCriticsRating {
                        RatingRow(
                            icon: critics >= 60 ? "theatermasks.fill" : "theatermasks",
                            iconColor: critics >= 60 ? .red : Color.green.opacity(0.6),
                            label: "RT Critics",
                            value: "\(critics)%"
                        )
                    }

                    // Rotten Tomatoes Audience
                    if let audience = rtAudienceRating {
                        RatingRow(
                            icon: "person.2.fill",
                            iconColor: .blue,
                            label: "RT Audience",
                            value: "\(audience)%"
                        )
                    }

                    Spacer()
                }
            )
        )
    }
}

/// Single rating row
private struct RatingRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(iconColor)
                .frame(width: 40)

            Text(label)
                .font(.system(size: 26))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(value)
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

/// Information card with key-value pairs
struct InfoCard: View {
    let items: [(key: String, value: String)]

    var body: some View {
        AboutCard(
            title: "Information",
            content: AnyView(
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        InfoRow(key: item.key, value: item.value)
                    }
                    Spacer()
                }
            )
        )
    }
}

/// Single info row
private struct InfoRow: View {
    let key: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key)
                .font(.system(size: 22))
                .foregroundColor(.white.opacity(0.6))

            Text(value)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

/// Poster image card
struct PosterImageCard: View {
    let posterPath: String?

    var body: some View {
        AboutCard(
            title: "Poster",
            content: AnyView(
                Group {
                    if let posterURL = TMDBImageHelper.posterURL(path: posterPath, size: .original) {
                        KFImage(posterURL)
                            .resizable()
                            .aspectRatio(2/3, contentMode: .fit)
                            .cornerRadius(12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white.opacity(0.3))
                            )
                    }
                }
                .frame(maxHeight: .infinity)
            )
        )
    }
}

/// Companies/Networks card with logos
struct CompaniesCard: View {
    let title: String
    let companies: [ProductionCompany]

    var body: some View {
        AboutCard(
            title: title,
            content: AnyView(
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(companies.prefix(6)) { company in
                            CompanyRow(company: company)
                        }
                    }
                }
            )
        )
    }
}

/// Single company row
private struct CompanyRow: View {
    let company: ProductionCompany

    var body: some View {
        HStack(spacing: 16) {
            // Logo if available
            if let logoPath = company.logoPath,
               let logoURL = TMDBImageHelper.logoURL(path: logoPath) {
                KFImage(logoURL)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 40)
            }

            // Company name
            Text(company.name)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .lineLimit(2)

            Spacer()
        }
    }
}

/// Crew card with directors, writers, producers
struct CrewCard: View {
    let crew: [(name: String, job: String)]

    var body: some View {
        AboutCard(
            title: "Crew",
            content: AnyView(
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(crew.indices, id: \.self) { index in
                            let member = crew[index]
                            CrewRow(name: member.name, job: member.job)
                        }
                    }
                }
            )
        )
    }
}

/// Single crew member row
private struct CrewRow: View {
    let name: String
    let job: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)

            Text(job)
                .font(.system(size: 22))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

/// Combined card with ratings at top and info items below
struct CombinedInfoCard: View {
    var tmdbRating: Double?
    var imdbRating: String?
    var rtCriticsRating: Int?
    var rtAudienceRating: Int?
    let infoItems: [(key: String, value: String)]

    var body: some View {
        AboutCard(
            title: "Information",
            content: AnyView(
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Ratings section
                        VStack(alignment: .leading, spacing: 16) {
                            // TMDB Rating
                            if let tmdb = tmdbRating {
                                RatingRow(
                                    icon: "star.fill",
                                    iconColor: .yellow,
                                    label: "TMDB",
                                    value: String(format: "%.1f/10", tmdb)
                                )
                            }

                            // IMDb Rating
                            if let imdb = imdbRating {
                                RatingRow(
                                    icon: "star.fill",
                                    iconColor: Color(red: 0.95, green: 0.77, blue: 0.18),
                                    label: "IMDb",
                                    value: "\(imdb)/10"
                                )
                            }

                            // Rotten Tomatoes Critics
                            if let critics = rtCriticsRating {
                                RatingRow(
                                    icon: critics >= 60 ? "theatermasks.fill" : "theatermasks",
                                    iconColor: critics >= 60 ? .red : Color.green.opacity(0.6),
                                    label: "RT Critics",
                                    value: "\(critics)%"
                                )
                            }

                            // Rotten Tomatoes Audience
                            if let audience = rtAudienceRating {
                                RatingRow(
                                    icon: "person.2.fill",
                                    iconColor: .blue,
                                    label: "RT Audience",
                                    value: "\(audience)%"
                                )
                            }
                        }

                        // Divider if we have both ratings and info
                        if hasRatings && !infoItems.isEmpty {
                            Divider()
                                .background(Color.white.opacity(0.2))
                        }

                        // Info items section
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(infoItems.indices, id: \.self) { index in
                                let item = infoItems[index]
                                InfoRow(key: item.key, value: item.value)
                            }
                        }
                    }
                }
            )
        )
    }

    private var hasRatings: Bool {
        tmdbRating != nil || imdbRating != nil || rtCriticsRating != nil || rtAudienceRating != nil
    }
}
