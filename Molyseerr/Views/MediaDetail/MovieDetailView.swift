//
//  MovieDetailView.swift
//  Molyseerr
//
//  Created by Claude on 29/12/2025.
//

import SwiftUI

/// Detailed view for a movie
/// Includes cinematic header, cast, crew, similar movies, recommendations, and about cards
struct MovieDetailView: View {
    let movieDetails: MovieDetails

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
                    backdropPath: movieDetails.backdropPath,
                    posterPath: movieDetails.posterPath,
                    title: movieDetails.displayTitle,
                    tagline: movieDetails.tagline,
                    overview: movieDetails.overview,
                    year: movieDetails.releaseYear,
                    runtime: movieDetails.formattedRuntime,
                    certification: movieDetails.certification,
                    genres: movieDetails.genres,
                    voteAverage: movieDetails.voteAverage,
                    mediaInfo: movieDetails.mediaInfo,
                    mediaType: .movie,
                    onRequest: {
                        showingRequestSheet = true
                    },
                    onPlayTrailer: movieDetails.trailerURL != nil ? {
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

                // Cast section
                if let cast = movieDetails.credits?.cast, !cast.isEmpty {
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

                // Additional details section (Overview and Studios)
                additionalDetailsSection
                    .padding(.top, sectionSpacing)

                // Similar movies
                if let similar = movieDetails.similar, !similar.isEmpty {
                    similarSection(items: similar)
                        .padding(.top, sectionSpacing)
                }

                // Recommendations
                if let recommendations = movieDetails.recommendations, !recommendations.isEmpty {
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
            RequestSheet(movieDetails: movieDetails) {
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

                                Text(movieDetails.voteAverage != nil ? String(format: "%.1f", movieDetails.voteAverage!) : "N/A")
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

    // Section 4: Additional details (Overview, Ratings, Poster, Studios)
    private var additionalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("More Details")
                .font(.system(size: 38, weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    // Overview card
                    if let overview = movieDetails.overview, !overview.isEmpty {
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
                            tmdbRating: movieDetails.voteAverage,
                            imdbRating: nil, // TODO: Fetch IMDb rating
                            rtCriticsRating: nil, // TODO: Fetch RT ratings
                            rtAudienceRating: nil
                        )
                    }
                    .buttonStyle(.borderless)

                    // Production companies
                    if let productionCompanies = movieDetails.productionCompanies, !productionCompanies.isEmpty {
                        Button {
                            // Card is informational only
                        } label: {
                            CompaniesCard(
                                title: "Studios",
                                companies: productionCompanies
                            )
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
    }

    private func similarSection(items: [MovieResult]) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Similar Movies")
                .font(.system(size: 38, weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 24) {
                    ForEach(items.prefix(20)) { movie in
                        Button {
                            // TODO: Navigate to movie detail
                            print("Tapped movie \(movie.id)")
                        } label: {
                            PosterCard(
                                posterPath: movie.posterPath,
                                width: 200,
                                height: 300,
                                overlay: nil
                            )
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
    }

    private func recommendationsSection(items: [MovieResult]) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Recommendations")
                .font(.system(size: 38, weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 24) {
                    ForEach(items.prefix(20)) { movie in
                        Button {
                            // TODO: Navigate to movie detail
                            print("Tapped movie \(movie.id)")
                        } label: {
                            PosterCard(
                                posterPath: movie.posterPath,
                                width: 200,
                                height: 300,
                                overlay: nil
                            )
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
    }

    // MARK: - Computed Properties

    /// Top crew members (Directors, Writers, Producers)
    private var topCrew: [CrewMember]? {
        guard let crew = movieDetails.credits?.crew else { return nil }

        let directors = crew.filter { $0.job == "Director" }.prefix(3).map { $0.asMember }
        let writers = crew.filter { $0.department == "Writing" }.prefix(3).map { $0.asMember }
        let producers = crew.filter { $0.job == "Producer" }.prefix(3).map { $0.asMember }

        let combined = Array(directors) + Array(writers) + Array(producers)
        return combined.isEmpty ? nil : Array(combined.prefix(6))
    }

    /// Info items for InfoCard
    private var infoItems: [(key: String, value: String)] {
        var items: [(key: String, value: String)] = []

        // Original title
        if let originalTitle = movieDetails.originalTitle, originalTitle != movieDetails.title {
            items.append(("Original Title", originalTitle))
        }

        // Status
        if let status = movieDetails.status {
            items.append(("Status", status))
        }

        // Release date
        if let releaseDateString = movieDetails.releaseDate, !releaseDateString.isEmpty {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
            if let date = formatter.date(from: releaseDateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .long
                items.append(("Release Date", displayFormatter.string(from: date)))
            }
        }

        // Budget
        if let budget = movieDetails.budget, budget > 0 {
            items.append(("Budget", formatCurrency(budget)))
        }

        // Revenue
        if let revenue = movieDetails.revenue, revenue > 0 {
            items.append(("Revenue", formatCurrency(revenue)))
        }

        // Original language
        if let originalLanguage = movieDetails.originalLanguage {
            items.append(("Original Language", originalLanguage.uppercased()))
        }

        return items
    }

    /// Detailed info items for combined card
    private var detailedInfoItems: [(key: String, value: String)] {
        var items: [(key: String, value: String)] = []

        // Original title
        if let originalTitle = movieDetails.originalTitle, originalTitle != movieDetails.title {
            items.append(("Original Title", originalTitle))
        }

        // Status
        if let status = movieDetails.status {
            items.append(("Status", status))
        }

        // Release date
        if let releaseDateString = movieDetails.releaseDate, !releaseDateString.isEmpty {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
            if let date = formatter.date(from: releaseDateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .long
                items.append(("Release Date", displayFormatter.string(from: date)))
            }
        }

        // Revenue
        if let revenue = movieDetails.revenue, revenue > 0 {
            items.append(("Revenue", formatCurrency(revenue)))
        }

        // Budget
        if let budget = movieDetails.budget, budget > 0 {
            items.append(("Budget", formatCurrency(budget)))
        }

        // Original language
        if let originalLanguage = movieDetails.originalLanguage {
            items.append(("Original Language", originalLanguage.uppercased()))
        }

        // Production country
        if let productionCompanies = movieDetails.productionCompanies, !productionCompanies.isEmpty {
            let countries = productionCompanies.compactMap { $0.originCountry }.filter { !$0.isEmpty }
            if !countries.isEmpty {
                items.append(("Production Country", countries.joined(separator: ", ")))
            }
        }

        // Studio
        if let productionCompanies = movieDetails.productionCompanies, !productionCompanies.isEmpty {
            items.append(("Studio", productionCompanies.first!.name))
        }

        return items
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
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

private extension MovieDetails {
    /// Get primary certification (US rating)
    var certification: String? {
        // TODO: Extract US certification from releases
        return nil
    }

    /// Get trailer URL
    var trailerURL: URL? {
        // TODO: Extract YouTube trailer URL from relatedVideos
        guard let videos = relatedVideos else { return nil }
        let trailer = videos.first { $0.type.lowercased() == "trailer" && $0.site.lowercased() == "youtube" }
        guard let key = trailer?.key else { return nil }
        return URL(string: "https://www.youtube.com/watch?v=\(key)")
    }

    /// Similar movies (placeholder - should be fetched separately)
    var similar: [MovieResult]? {
        // TODO: Fetch similar movies
        return nil
    }

    /// Recommended movies (placeholder - should be fetched separately)
    var recommendations: [MovieResult]? {
        // TODO: Fetch recommendations
        return nil
    }
}

private extension Crew {
    var asMember: CrewMember {
        CrewMember(name: name, job: job, department: department)
    }
}
