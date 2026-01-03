//
//  EpisodeSelector.swift
//  Molyseerr
//
//  Created by Claude on 30/12/2025.
//

import SwiftUI

/// Main episode selector component inspired by Swiftfin
/// Combines season selector and episode grid
struct EpisodeSelector: View {
    let tvDetails: TVDetails
    @State private var selectedSeasonNumber: Int?
    @State private var episodes: [Episode] = []
    @State private var isLoadingEpisodes = false
    @EnvironmentObject private var configManager: ConfigManager

    private let horizontalPadding: CGFloat = 90

    /// Get user's preferred language for metadata
    private var userLanguage: String {
        configManager.currentUser?.preferredLocale ?? "en"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title - "Seasons" localized
            Text(localizedSeasonsTitle)
                .font(.system(size: 38, weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, horizontalPadding)
                .padding(.top, 20)

            // Season selector
            if let seasons = tvDetails.seasons, !seasons.isEmpty {
                let filteredSeasons = seasons.sorted { $0.seasonNumber < $1.seasonNumber }
                SeasonsSelector(
                    seasons: filteredSeasons,
                    selectedSeasonNumber: $selectedSeasonNumber
                )
            }

            // Episodes grid
            if isLoadingEpisodes {
                loadingView
                    .padding(.horizontal, horizontalPadding)
            } else if !episodes.isEmpty {
                episodesGrid
            } else if selectedSeasonNumber != nil {
                emptyView
                    .padding(.horizontal, horizontalPadding)
            }
        }
        .onAppear {
            // Select first season by default (sorted by season number)
            if let seasons = tvDetails.seasons?.sorted(by: { $0.seasonNumber < $1.seasonNumber }), !seasons.isEmpty {
                selectedSeasonNumber = seasons.first?.seasonNumber
            }
        }
        .onChange(of: selectedSeasonNumber) { _, newSeasonNumber in
            if let newSeasonNumber = newSeasonNumber {
                loadEpisodes(seasonNumber: newSeasonNumber)
            }
        }
    }

    // MARK: - Subviews

    private var episodesGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 40) {
                ForEach(episodes) { episode in
                    EpisodeCard(episode: episode) {
                        // TODO: Navigate to episode detail or play episode
                        print("Tapped episode \(episode.id)")
                    }
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 30)
        }
    }

    private var loadingView: some View {
        HStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading episodes...")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tv.slash")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.5))

            Text("No episodes available")
                .font(.system(size: 26))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Localization

    /// Localized title for "Seasons" based on user's preferred language
    private var localizedSeasonsTitle: String {
        let locale = userLanguage
        let translations: [String: String] = [
            "ar": "المواسم",            // Arabic (plural of season)
            "cs": "Sezóny",            // Czech
            "da": "Sæsoner",           // Danish
            "de": "Staffeln",          // German
            "el": "Κύκλοι",            // Greek
            "en": "Seasons",           // English
            "es": "Temporadas",        // Spanish
            "fi": "Kaudet",            // Finnish
            "fr": "Saisons",           // French
            "he": "עונות",             // Hebrew
            "hr": "Sezone",            // Croatian
            "hu": "Évadok",            // Hungarian
            "it": "Stagioni",          // Italian
            "ja": "シーズン",           // Japanese
            "ko": "시즌",               // Korean
            "nl": "Seizoenen",         // Dutch
            "no": "Sesonger",          // Norwegian
            "pl": "Sezony",            // Polish
            "pt": "Temporadas",        // Portuguese
            "pt-BR": "Temporadas",     // Portuguese (Brazil)
            "ro": "Sezoane",           // Romanian
            "ru": "Сезоны",            // Russian
            "sk": "Série",             // Slovak
            "sv": "Säsonger",          // Swedish
            "th": "ซีซัน",             // Thai
            "tr": "Sezonlar",          // Turkish
            "uk": "Сезони",            // Ukrainian
            "zh": "季",                // Chinese
            "zh-CN": "季",             // Chinese (Simplified)
            "zh-TW": "季"              // Chinese (Traditional)
        ]
        return translations[locale] ?? "Seasons"
    }

    // MARK: - Data Loading

    private func loadEpisodes(seasonNumber: Int) {
        isLoadingEpisodes = true
        episodes = []

        Task {
            do {
                // Fetch episodes using the configured metadata provider (TMDB or TVDB)
                let fetchedEpisodes: [Episode]

                switch tvDetails.metadataProvider {
                case .tmdb(let tmdbId):
                    print("Fetching episodes from TMDB for season \(seasonNumber) (language: \(userLanguage))")
                    let tmdbEpisodes = try await TMDBService.shared.fetchSeasonDetails(
                        tvID: tmdbId,
                        seasonNumber: seasonNumber,
                        language: userLanguage
                    )
                    fetchedEpisodes = tmdbEpisodes.map { Episode(from: $0) }
                case .tvdb(let tvdbId):
                    print("Fetching episodes from TVDB (id: \(tvdbId)) for season \(seasonNumber) (language: \(userLanguage))")
                    do {
                        fetchedEpisodes = try await TVDBService.shared.fetchSeasonDetails(
                            tvdbId: tvdbId,
                            seasonNumber: seasonNumber,
                            language: userLanguage
                        )
                    } catch {
                        // Fallback to TMDB if TVDB fails
                        print("TVDB failed, falling back to TMDB: \(error)")
                        let tmdbEpisodes = try await TMDBService.shared.fetchSeasonDetails(
                            tvID: tvDetails.id,
                            seasonNumber: seasonNumber,
                            language: userLanguage
                        )
                        fetchedEpisodes = tmdbEpisodes.map { Episode(from: $0) }
                    }
                }

                await MainActor.run {
                    episodes = fetchedEpisodes
                    isLoadingEpisodes = false
                }
            } catch {
                print("Error loading episodes: \(error)")
                await MainActor.run {
                    episodes = []
                    isLoadingEpisodes = false
                }
            }
        }
    }
}
