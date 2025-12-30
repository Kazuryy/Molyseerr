//
//  SeriesDetailView.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI
import Kingfisher

/// Detailed view for a TV series
/// Includes cinematic header, seasons selector, cast, crew, similar series, and about cards
struct SeriesDetailView: View {
    let tvDetails: TVDetails

    @State private var showingRequestSheet = false
    @State private var toast: ToastConfig?
    @FocusState private var focusedCastID: Int?
    @FocusState private var isCrewFocused: Bool
    @FocusState private var isInfoFocused: Bool

    private let horizontalPadding: CGFloat = 90
    private let sectionSpacing: CGFloat = 60

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                // Cinematic header
                CinematicHeaderView(
                    backdropPath: tvDetails.backdropPath,
                    posterPath: tvDetails.posterPath,
                    title: tvDetails.displayName,
                    tagline: tvDetails.tagline,
                    overview: tvDetails.overview,
                    year: tvDetails.firstAirYear,
                    runtime: tvDetails.formattedRuntime,
                    certification: tvDetails.contentRating,
                    genres: tvDetails.genres,
                    voteAverage: tvDetails.voteAverage,
                    mediaInfo: tvDetails.mediaInfo,
                    mediaType: .tv,
                    onRequest: {
                        showingRequestSheet = true
                    },
                    onPlayTrailer: tvDetails.trailerURL != nil ? {
                        // TODO: Play trailer
                        print("Play trailer")
                    } : nil,
                    onToggleWatchlist: {
                        // TODO: Toggle watchlist
                        print("Toggle watchlist")
                    }
                )

                // Crew and Information section (two columns)
                crewAndInfoSection
                    .padding(.top, sectionSpacing)

                // Episodes section (with season selector)
                if let seasons = tvDetails.seasons, !seasons.isEmpty {
                    EpisodeSelector(tvDetails: tvDetails)
                        .padding(.top, sectionSpacing)
                }

                // Cast section
                if let cast = tvDetails.credits?.cast, !cast.isEmpty {
                    VStack(spacing: 24) {
                        Text("Cast")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.leading, horizontalPadding)

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 30) {
                                ForEach(cast.prefix(20)) { member in
                                    Button {
                                        // TODO: Navigate to person detail
                                        print("Tapped \(member.name)")
                                    } label: {
                                        CastPosterCard(cast: member, isFocused: focusedCastID == member.id)
                                    }
                                    .buttonStyle(.borderless)
                                    .focused($focusedCastID, equals: member.id)
                                }
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.vertical, 20)
                        }
                    }
                    .padding(.top, sectionSpacing)
                }

                // Additional details section (Overview and Networks)
                additionalDetailsSection
                    .padding(.top, sectionSpacing)

                // Similar series
                if let similar = tvDetails.similar, !similar.isEmpty {
                    similarSection(items: similar)
                        .padding(.top, sectionSpacing)
                }

                // Recommendations
                if let recommendations = tvDetails.recommendations, !recommendations.isEmpty {
                    recommendationsSection(items: recommendations)
                        .padding(.top, sectionSpacing)
                }

                // Bottom spacing
                Color.clear
                    .frame(height: 100)
            }
        }
        .background(Color.Seerr.background)
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $showingRequestSheet) {
            RequestSheet(tvDetails: tvDetails) {
                // Refresh data after request
                print("Request completed, should refresh")
            }
        }
        .toast($toast)
    }

    // MARK: - Subviews

    // Section 2: Crew and Information in two columns (webapp style - matching Seerr CSS)
    private var crewAndInfoSection: some View {
        HStack(alignment: .top, spacing: 32) {
            // Left column: Crew (flex-1 with mr-8 like webapp)
            if let crew = topCrew {
                Button {
                    // Focusable crew section
                } label: {
                    VStack(alignment: .leading, spacing: 32) {
                        Text("Crew")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)

                        // Grid layout: 2 columns with 32px gap
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 32) {
                            ForEach(crew.indices, id: \.self) { index in
                                let member = crew[index]
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(member.job)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(Color(red: 209/255, green: 213/255, blue: 219/255)) // gray-300

                                    Text(member.name)
                                        .font(.system(size: 26))
                                        .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255)) // gray-400
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isCrewFocused ? Color.white.opacity(0.1) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isCrewFocused ? Color.Seerr.indigo : Color.clear, lineWidth: 3)
                    )
                }
                .buttonStyle(.borderless)
                .focused($isCrewFocused)
            }

            // Right column: Media Facts (larger width for better visibility)
            Button {
                // Focusable info section
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    // Ratings section (matching media-ratings style)
                    VStack(spacing: 0) {
                        HStack(spacing: 24) {
                            // TMDB Rating - Always show even if nil for debugging
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.yellow)

                                Text(tvDetails.voteAverage != nil ? String(format: "%.1f", tvDetails.voteAverage!) : "N/A")
                                    .font(.system(size: 26, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 17/255, green: 24/255, blue: 39/255)) // gray-900
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(red: 55/255, green: 65/255, blue: 81/255)), // gray-700
                            alignment: .bottom
                        )
                    }

                    // Information facts (matching media-fact style)
                    VStack(spacing: 0) {
                        ForEach(detailedInfoItems.indices, id: \.self) { index in
                            let item = detailedInfoItems[index]
                            let isLast = index == detailedInfoItems.count - 1

                            HStack {
                                Text(item.key)
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(Color(red: 209/255, green: 213/255, blue: 219/255)) // gray-300

                                Spacer()

                                Text(item.value)
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255)) // gray-400
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(red: 17/255, green: 24/255, blue: 39/255)) // gray-900
                            .overlay(
                                Rectangle()
                                    .frame(height: isLast ? 0 : 1)
                                    .foregroundColor(Color(red: 55/255, green: 65/255, blue: 81/255)), // gray-700
                                alignment: .bottom
                            )
                        }
                    }
                }
                .frame(width: 600) // Increased from 500px for larger text
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isInfoFocused ? Color.Seerr.indigo : Color(red: 55/255, green: 65/255, blue: 81/255), lineWidth: isInfoFocused ? 3 : 1)
                )
                .shadow(color: isInfoFocused ? Color.Seerr.indigo.opacity(0.3) : .black.opacity(0.1), radius: isInfoFocused ? 10 : 4)
            }
            .buttonStyle(.borderless)
            .focused($isInfoFocused)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, 32)
        .padding(.bottom, 16)
    }

    // Section 4: Additional details (Overview, Ratings, Poster, Networks)
    private var additionalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("More Details")
                .font(.system(size: 38, weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    // Overview card
                    if let overview = tvDetails.overview, !overview.isEmpty {
                        Button {
                            // Card is informational only
                        } label: {
                            OverviewCard(overview: overview)
                        }
                        .buttonStyle(.borderless)
                    }

                    // Ratings card
                    Button {
                        // Card is informational only
                    } label: {
                        RatingsCard(
                            tmdbRating: tvDetails.voteAverage,
                            imdbRating: nil, // TODO: Fetch IMDb rating
                            rtCriticsRating: nil, // TODO: Fetch RT ratings
                            rtAudienceRating: nil
                        )
                    }
                    .buttonStyle(.borderless)

                    // Networks
                    if let networks = tvDetails.networks, !networks.isEmpty {
                        Button {
                            // Card is informational only
                        } label: {
                            CompaniesCard(
                                title: "Networks",
                                companies: networks
                            )
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
    }

    private func similarSection(items: [TVResult]) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Similar Series")
                .font(.system(size: 38, weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 24) {
                    ForEach(items.prefix(20)) { series in
                        Button {
                            // TODO: Navigate to series detail
                            print("Tapped series \(series.id)")
                        } label: {
                            PosterCard(
                                posterPath: series.posterPath,
                                width: 200,
                                height: 300,
                                overlay: nil
                            )
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                            .padding(.vertical, 20)
            }
        }
    }

    private func recommendationsSection(items: [TVResult]) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Recommendations")
                .font(.system(size: 38, weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 24) {
                    ForEach(items.prefix(20)) { series in
                        Button {
                            // TODO: Navigate to series detail
                            print("Tapped series \(series.id)")
                        } label: {
                            PosterCard(
                                posterPath: series.posterPath,
                                width: 200,
                                height: 300,
                                overlay: nil
                            )
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                            .padding(.vertical, 20)
            }
        }
    }

    // MARK: - Computed Properties

    /// Top crew members (Creators, Writers, Producers)
    private var topCrew: [CrewMember]? {
        var crewMembers: [CrewMember] = []

        // Add creators
        if let creators = tvDetails.createdBy {
            for creator in creators {
                crewMembers.append(CrewMember(name: creator.name, job: "Creator", department: "Production"))
            }
        }

        // Add other crew
        if let crew = tvDetails.credits?.crew {
            let writers = crew.filter { $0.department == "Writing" }.prefix(3)
            let producers = crew.filter { $0.job == "Producer" }.prefix(3)

            crewMembers += writers.map { $0.asMember }
            crewMembers += producers.map { $0.asMember }
        }

        return crewMembers.isEmpty ? nil : Array(crewMembers.prefix(6))
    }

    /// Info items for InfoCard
    private var infoItems: [(key: String, value: String)] {
        var items: [(key: String, value: String)] = []

        // Original name
        if let originalName = tvDetails.originalName, originalName != tvDetails.name {
            items.append(("Original Name", originalName))
        }

        // Status
        if let status = tvDetails.status {
            items.append(("Status", status))
        }

        // First air date
        if let firstAirDateString = tvDetails.firstAirDate, !firstAirDateString.isEmpty {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
            if let date = formatter.date(from: firstAirDateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .long
                items.append(("First Aired", displayFormatter.string(from: date)))
            }
        }

        // Number of seasons
        if let numberOfSeasons = tvDetails.numberOfSeasons {
            items.append(("Seasons", "\(numberOfSeasons)"))
        }

        // Number of episodes
        if let numberOfEpisodes = tvDetails.numberOfEpisodes {
            items.append(("Episodes", "\(numberOfEpisodes)"))
        }

        // Original language
        if let originalLanguage = tvDetails.originalLanguage {
            items.append(("Original Language", originalLanguage.uppercased()))
        }

        return items
    }

    /// Detailed info items for combined card
    private var detailedInfoItems: [(key: String, value: String)] {
        var items: [(key: String, value: String)] = []

        // Original name
        if let originalName = tvDetails.originalName, originalName != tvDetails.name {
            items.append(("Original Name", originalName))
        }

        // Status
        if let status = tvDetails.status {
            items.append(("Status", status))
        }

        // First air date
        if let firstAirDateString = tvDetails.firstAirDate, !firstAirDateString.isEmpty {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
            if let date = formatter.date(from: firstAirDateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .long
                items.append(("First Aired", displayFormatter.string(from: date)))
            }
        }

        // Last air date
        if let lastAirDateString = tvDetails.lastAirDate, !lastAirDateString.isEmpty {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
            if let date = formatter.date(from: lastAirDateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .long
                items.append(("Last Aired", displayFormatter.string(from: date)))
            }
        }

        // Number of seasons
        if let numberOfSeasons = tvDetails.numberOfSeasons {
            items.append(("Seasons", "\(numberOfSeasons)"))
        }

        // Number of episodes
        if let numberOfEpisodes = tvDetails.numberOfEpisodes {
            items.append(("Episodes", "\(numberOfEpisodes)"))
        }

        // Original language
        if let originalLanguage = tvDetails.originalLanguage {
            items.append(("Original Language", originalLanguage.uppercased()))
        }

        // Production country
        if let originCountry = tvDetails.originCountry, !originCountry.isEmpty {
            items.append(("Production Country", originCountry.joined(separator: ", ")))
        }

        // Network
        if let networks = tvDetails.networks, !networks.isEmpty {
            items.append(("Network", networks.first!.name))
        }

        return items
    }
}

// MARK: - Crew Member Type

private struct CrewMember: Identifiable {
    let name: String
    let job: String
    let department: String

    var id: String {
        "\(name)-\(job)-\(department)"
    }
}

// MARK: - Extensions

private extension TVDetails {
    /// Get content rating (US rating)
    var contentRating: String? {
        // TODO: Extract US content rating from contentRatings
        return nil
    }

    /// Get trailer URL
    var trailerURL: URL? {
        // TODO: Extract YouTube trailer URL from relatedVideos
        return nil
    }

    /// Similar series (placeholder - should be fetched separately)
    var similar: [TVResult]? {
        // TODO: Fetch similar series
        return nil
    }

    /// Recommended series (placeholder - should be fetched separately)
    var recommendations: [TVResult]? {
        // TODO: Fetch recommendations
        return nil
    }
}

private extension Crew {
    var asMember: CrewMember {
        CrewMember(name: name, job: job, department: department)
    }
}
