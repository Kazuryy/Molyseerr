//
//  SeasonsSelector.swift
//  Molyseerr
//
//  Created by Claude on 30/12/2025.
//

import SwiftUI

/// Horizontal season selector inspired by Swiftfin
/// Displays a row of season buttons to switch between seasons
struct SeasonsSelector: View {
    let seasons: [Season]
    @Binding var selectedSeasonNumber: Int?

    @EnvironmentObject private var configManager: ConfigManager

    @FocusState private var focusedSeasonNumber: Int?
    @State private var didScrollToSelectedSeason = false

    private let horizontalPadding: CGFloat = 90
    private let buttonSpacing: CGFloat = 22

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: buttonSpacing) {
                    ForEach(seasons, id: \.seasonNumber) { season in
                        seasonButton(season: season)
                            .id(season.seasonNumber)
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
            .padding(.bottom, 45)
            .mask {
                VStack(spacing: 0) {
                    Color.white

                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 20)
                }
            }
            .onChange(of: focusedSeasonNumber) { _, newValue in
                if let newValue = newValue {
                    selectedSeasonNumber = newValue
                }
            }
            .onAppear {
                guard !didScrollToSelectedSeason else { return }
                didScrollToSelectedSeason = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    guard let selectedSeasonNumber = selectedSeasonNumber else { return }
                    proxy.scrollTo(selectedSeasonNumber)
                }
            }
        }
        .scrollClipDisabled()
    }

    // MARK: - Season Button

    @ViewBuilder
    private func seasonButton(season: Season) -> some View {
        let isSelected = selectedSeasonNumber == season.seasonNumber

        Button {
            selectedSeasonNumber = season.seasonNumber
        } label: {
            Text(localizedSeasonTitle(for: season))
                .frame(maxWidth: 300)
                .font(.system(size: 26, weight: .semibold))
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(isSelected ? Color.white : Color.clear)
                .foregroundColor(isSelected ? .black : .white)
        }
        .focused($focusedSeasonNumber, equals: season.seasonNumber)
        .buttonStyle(.card)
        .padding(.horizontal, 4)
        .padding(.vertical)
    }

    // MARK: - Localization

    /// Generate localized season title based on user's preferred language
    /// NOTE: We IGNORE TMDB season names and always generate localized titles
    /// This ensures consistency whether using TMDB or TVDB metadata
    private func localizedSeasonTitle(for season: Season) -> String {
        // Get user's locale (default to English)
        let locale = configManager.currentUser?.preferredLocale ?? "en"

        print("🏷️ Season \(season.seasonNumber) - locale: \(locale)")

        // Handle specials (season 0)
        if season.seasonNumber == 0 {
            let title = localizeSpecials(locale: locale)
            print("🏷️ Season 0 → \(title)")
            return title
        }

        // Regular seasons: "Season N" or translated equivalent
        // We ALWAYS generate the title ourselves, never use TMDB names
        let seasonWord = localizeSeason(locale: locale)
        let title = "\(seasonWord) \(season.seasonNumber)"
        print("🏷️ Season \(season.seasonNumber) → \(title)")
        return title
    }

    /// Translate "Season" based on user's locale
    private func localizeSeason(locale: String) -> String {
        // Based on Seerr's supported languages
        let translations: [String: String] = [
            "ar": "موسم",              // Arabic
            "cs": "Sezóna",           // Czech
            "da": "Sæson",            // Danish
            "de": "Staffel",          // German
            "el": "Κύκλος",           // Greek
            "en": "Season",           // English
            "es": "Temporada",        // Spanish
            "fi": "Kausi",            // Finnish
            "fr": "Saison",           // French
            "he": "עונה",             // Hebrew
            "hr": "Sezona",           // Croatian
            "hu": "Évad",             // Hungarian
            "it": "Stagione",         // Italian
            "ja": "シーズン",          // Japanese
            "ko": "시즌",              // Korean
            "nl": "Seizoen",          // Dutch
            "no": "Sesong",           // Norwegian
            "pl": "Sezon",            // Polish
            "pt": "Temporada",        // Portuguese
            "pt-BR": "Temporada",     // Portuguese (Brazil)
            "ro": "Sezonul",          // Romanian
            "ru": "Сезон",            // Russian
            "sk": "Séria",            // Slovak
            "sv": "Säsong",           // Swedish
            "th": "ซีซัน",            // Thai
            "tr": "Sezon",            // Turkish
            "uk": "Сезон",            // Ukrainian
            "zh": "季",               // Chinese
            "zh-CN": "季",            // Chinese (Simplified)
            "zh-TW": "季"             // Chinese (Traditional)
        ]
        return translations[locale] ?? "Season"
    }

    /// Translate "Specials" based on user's locale
    private func localizeSpecials(locale: String) -> String {
        // Based on Seerr's supported languages
        let translations: [String: String] = [
            "ar": "حلقات خاصة",        // Arabic
            "cs": "Speciály",         // Czech
            "da": "Specialafsnit",    // Danish
            "de": "Specials",         // German
            "el": "Ειδικά",           // Greek
            "en": "Specials",         // English
            "es": "Especiales",       // Spanish
            "fi": "Erikoisjaksot",    // Finnish
            "fr": "Spéciaux",         // French
            "he": "מיוחדים",          // Hebrew
            "hr": "Specijali",        // Croatian
            "hu": "Különkiadások",    // Hungarian
            "it": "Speciali",         // Italian
            "ja": "スペシャル",        // Japanese
            "ko": "스페셜",            // Korean
            "nl": "Specials",         // Dutch
            "no": "Spesialavsnitt",   // Norwegian
            "pl": "Odcinki specjalne", // Polish
            "pt": "Especiais",        // Portuguese
            "pt-BR": "Especiais",     // Portuguese (Brazil)
            "ro": "Speciale",         // Romanian
            "ru": "Специальные выпуски", // Russian
            "sk": "Špeciály",         // Slovak
            "sv": "Specialavsnitt",   // Swedish
            "th": "ตอนพิเศษ",         // Thai
            "tr": "Özel Bölümler",    // Turkish
            "uk": "Спеціальні випуски", // Ukrainian
            "zh": "特别篇",           // Chinese
            "zh-CN": "特别篇",        // Chinese (Simplified)
            "zh-TW": "特別篇"         // Chinese (Traditional)
        ]
        return translations[locale] ?? "Specials"
    }
}
