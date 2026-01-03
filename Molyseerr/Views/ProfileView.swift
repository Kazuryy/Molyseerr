//
//  ProfileView.swift
//  Molyseerr
//
//  Created by Claude on 01/01/2026.
//

import SwiftUI
import Combine
import Kingfisher

/// User profile view showing quota, requests, and watchlist
/// Based on Seerr webapp UserProfile component
struct ProfileView: View {
    @EnvironmentObject var configManager: ConfigManager
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Top section: Profile Info + Quotas (left) | Settings (right)
                    HStack(alignment: .top, spacing: 60) {
                        // Left: Profile + Quotas
                        VStack(spacing: 40) {
                            if let user = configManager.currentUser {
                                // Profile info
                                VStack(spacing: 20) {
                                    avatarView(for: user)

                                    VStack(spacing: 10) {
                                        Text(user.displayName)
                                            .font(.system(size: 36, weight: .bold))
                                            .foregroundColor(.white)

                                        if let email = user.email, email != user.displayName {
                                            Text(email)
                                                .font(.system(size: 16))
                                                .foregroundColor(.Seerr.secondaryText)
                                        }

                                        HStack(spacing: 6) {
                                            Image(systemName: "calendar")
                                                .font(.system(size: 14))
                                            Text("Joined \(user.joinDate)")
                                                .font(.system(size: 14))
                                        }
                                        .foregroundColor(.Seerr.secondaryText)
                                    }

                                    // Total requests
                                    if let requestCount = user.requestCount {
                                        VStack(spacing: 6) {
                                            Text("\(requestCount)")
                                                .font(.system(size: 40, weight: .bold))
                                                .foregroundColor(.Seerr.primary)
                                            Text("Total Requests")
                                                .font(.system(size: 16))
                                                .foregroundColor(.Seerr.secondaryText)
                                        }
                                    }
                                }

                                // Quotas
                                if let quota = viewModel.quota {
                                    VStack(spacing: 24) {
                                        Text("Request Quotas")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        quotaRow(quota: quota.movie, icon: "film.fill", title: "Movie Requests")
                                        quotaRow(quota: quota.tv, icon: "tv.fill", title: "Series Requests")
                                    }
                                    .padding(30)
                                    .background(Color.Seerr.cardBackground)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .frame(width: 500)

                        // Right: Settings/Options
                        settingsSection
                            .frame(width: 600)
                    }
                    .padding(.horizontal, 60)
                    .padding(.top, 60)
                    .padding(.bottom, 40)

                    // Watchlist section (grid layout like library)
                    if !viewModel.watchlistItems.isEmpty {
                        watchlistGridSection
                    }

                    // Requests section (horizontal carousel)
                    if !viewModel.requestItems.isEmpty {
                        RequestsMediaRow(title: "Recent Requests", requests: viewModel.requests)
                    }

                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        errorView(message: errorMessage)
                            .padding(.horizontal, 60)
                            .padding(.bottom, 60)
                    }
                }
                .frame(maxWidth: .infinity)  // Ensure VStack takes full width
            }
            .background(Color.Seerr.background)
            .navigationBarHidden(true)  // Hide the fixed navigation bar
            .navigationDestination(for: MediaResult.self) { mediaResult in
                MediaDetailView(mediaResult: mediaResult)
            }
            .task {
                if let user = configManager.currentUser {
                    await viewModel.loadProfile(userId: user.id)
                }
            }
        }
    }

    // MARK: - Watchlist Grid Section

    private var watchlistGridSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section title
            Text("Watchlist")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.leading, 60)

            // Grid layout with 6 columns
            let itemsPerRow = 6
            let rows = stride(from: 0, to: viewModel.watchlistItems.count, by: itemsPerRow).map { rowIndex in
                Array(viewModel.watchlistItems[rowIndex..<min(rowIndex + itemsPerRow, viewModel.watchlistItems.count)])
            }

            VStack(spacing: 50) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, rowItems in
                    HStack(spacing: 50) {
                        ForEach(rowItems) { item in
                            MediaCardView(item: item)
                        }

                        // Add spacers for incomplete rows to maintain alignment
                        if rowItems.count < itemsPerRow {
                            ForEach(0..<(itemsPerRow - rowItems.count), id: \.self) { _ in
                                Color.clear
                                    .frame(width: 250, height: 375)
                            }
                        }
                    }
                    .focusSection()  // Each row is a focus section for smart navigation
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
    }

    // MARK: - Settings Section

    @ViewBuilder
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Settings")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 16) {
                // Language selector
                HStack {
                    Text("Language")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    Spacer()
                    Picker("", selection: .constant("en")) {
                        Text("English").tag("en")
                        Text("Français").tag("fr")
                        Text("Español").tag("es")
                        Text("Deutsch").tag("de")
                    }
                    .pickerStyle(.menu)
                }
                .padding(.vertical, 12)

                Divider()
                    .background(Color.gray.opacity(0.3))

                // Sign Out button with native focus
                Button {
                    // TODO: Implement logout
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 18))
                        Text("Sign Out")
                            .font(.system(size: 18))
                    }
                    .foregroundColor(.Seerr.statusError)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 12)
            }
        }
        .padding(30)
        .background(Color.Seerr.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(.Seerr.statusError)
            Text(message)
                .font(.system(size: 20))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(20)
        .background(Color.Seerr.statusError.opacity(0.2))
        .cornerRadius(8)
    }

    // MARK: - Quota Row Helper

    private func quotaRow(quota: QuotaStatus, icon: String, title: String) -> some View {
        HStack(spacing: 20) {
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 80, height: 80)

                if !quota.isUnlimited {
                    Circle()
                        .trim(from: 0, to: quotaRemaining(quota))
                        .stroke(
                            quotaColor(quota),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                }

                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)

                Text(quota.quotaText)
                    .font(.system(size: 18))
                    .foregroundColor(.Seerr.secondaryText)

                if let days = quota.days, !quota.isUnlimited {
                    Text("Past \(days) days")
                        .font(.system(size: 16))
                        .foregroundColor(.Seerr.secondaryText)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private func quotaRemaining(_ quota: QuotaStatus) -> CGFloat {
        guard let limit = quota.limit, limit > 0, let remaining = quota.remaining else { return 1.0 }
        let remainingValue = CGFloat(remaining)
        let total = CGFloat(limit)
        return remainingValue / total
    }

    private func quotaColor(_ quota: QuotaStatus) -> Color {
        if quota.restricted {
            return Color.Seerr.statusError
        }

        guard let limit = quota.limit, limit > 0, let remaining = quota.remaining else {
            return Color.Seerr.primary
        }

        let percentage = Double(remaining) / Double(limit)

        if percentage > 0.5 {
            return Color.Seerr.statusAvailable  // Green when plenty remaining
        } else if percentage > 0.25 {
            return Color.Seerr.statusPending    // Yellow when getting low
        } else {
            return Color.Seerr.statusError      // Red when very low
        }
    }

    @ViewBuilder
    private func avatarView(for user: User) -> some View {
        if let avatar = user.avatar, !avatar.isEmpty {
            // Avatar is a path like "/avatarproxy/xxx?v=xxx" - build full URL with server
            let fullAvatarURL = "\(configManager.baseURL)\(avatar)"
            let avatarURL = URL(string: fullAvatarURL)

            // Build KFImage with authentication
            let kfImage = KFImage(avatarURL)
                .placeholder {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .foregroundColor(.Seerr.primary)
                }

            // Apply authentication headers if we have a session cookie
            if let sessionCookie = UserDefaults.standard.string(forKey: "sessionCookie") {
                let modifier = AnyModifier { request in
                    var r = request
                    r.setValue("connect.sid=\(sessionCookie)", forHTTPHeaderField: "Cookie")
                    return r
                }
                kfImage
                    .requestModifier(modifier)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
            } else {
                kfImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
            }
        } else {
            // Fallback to icon if no avatar
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .foregroundColor(.Seerr.primary)
        }
    }
}

// MARK: - Profile ViewModel

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var quota: UserQuotaResponse?
    @Published var watchlistItems: [MediaResult] = []
    @Published var requestItems: [MediaResult] = []
    @Published var requests: [MediaRequest] = []  // Keep original requests for status/user info
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func loadProfile(userId: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            // Load quota, watchlist, and requests in parallel
            async let quotaTask = SeerrService.shared.getUserQuota(userId: userId)
            async let watchlistTask = SeerrService.shared.getUserWatchlist(userId: userId, page: 1)
            async let requestsTask = SeerrService.shared.getRequestList(
                filter: "all",
                sort: "added",
                take: 10,
                requestedBy: userId
            )

            quota = try await quotaTask
            let watchlistResponse = try await watchlistTask
            let requestsResponse = try await requestsTask

            // Convert watchlist items to MediaResult
            watchlistItems = await fetchWatchlistMediaResults(items: watchlistResponse.results)

            // Enrich requests with TMDB data (backdrop/poster) and store
            requests = await enrichRequestsWithTMDB(requests: requestsResponse.results)

            // Convert requests to MediaResult
            print("🎬 ProfileView: Converting \(requestsResponse.results.count) requests to MediaResult")
            requestItems = requestsResponse.results.compactMap { request in
                guard let media = request.media, let mediaType = media.mediaType else {
                    print("⚠️ Request \(request.id) has no media or mediaType")
                    return nil
                }

                print("✅ Request: \(media.title ?? "Unknown") - posterPath: \(media.posterPath ?? "nil")")

                if mediaType == .movie {
                    return MediaResult.movie(MovieResult(
                        id: media.tmdbId,
                        adult: nil,
                        backdropPath: media.backdropPath,
                        posterPath: media.posterPath,
                        genreIds: nil,
                        originalLanguage: media.originalLanguage,
                        originalTitle: media.originalTitle,
                        overview: media.overview,
                        popularity: media.popularity,
                        releaseDate: media.releaseDate,
                        firstAirDate: nil,
                        title: media.title,
                        name: nil,
                        originCountry: media.originCountry,
                        originalName: nil,
                        video: nil,
                        voteAverage: media.voteAverage,
                        voteCount: media.voteCount,
                        mediaType: "movie",
                        mediaInfo: media
                    ))
                } else {
                    return MediaResult.tv(TVResult(
                        id: media.tmdbId,
                        backdropPath: media.backdropPath,
                        posterPath: media.posterPath,
                        genreIds: nil,
                        originalLanguage: media.originalLanguage,
                        originalName: media.originalTitle,
                        overview: media.overview,
                        popularity: media.popularity,
                        firstAirDate: media.firstAirDate,
                        name: media.title ?? "Unknown",
                        voteAverage: media.voteAverage,
                        voteCount: media.voteCount,
                        originCountry: media.originCountry,
                        mediaType: "tv",
                        mediaInfo: media
                    ))
                }
            }

            isLoading = false
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func fetchWatchlistMediaResults(items: [WatchlistItem]) async -> [MediaResult] {
        print("🎬 ProfileView: Fetching \(items.count) watchlist items")

        let tmdbService = TMDBService.shared
        let seerrService = SeerrService.shared

        // Fetch all items in parallel for better performance
        let results = await withTaskGroup(of: MediaResult?.self) { group in
            for item in items {
                guard let tmdbId = item.tmdbId else { continue }

                group.addTask {
                    do {
                        if item.mediaTypeEnum == .movie {
                            // Fetch from both TMDB (for poster) and Seerr (for status) in parallel
                            async let tmdbDetails = tmdbService.getMovieDetails(id: tmdbId)
                            async let seerrDetails = try? seerrService.getMovieDetails(id: tmdbId)

                            let (tmdb, seerr) = try await (tmdbDetails, seerrDetails)
                            print("✅ Fetched movie: \(tmdb.title) - posterPath: \(tmdb.posterPath ?? "nil")")

                            return MediaResult.movie(MovieResult(
                                id: tmdb.id,
                                adult: tmdb.adult,
                                backdropPath: tmdb.backdropPath,
                                posterPath: tmdb.posterPath,  // Use TMDB posterPath
                                genreIds: tmdb.genres?.map { $0.id },
                                originalLanguage: tmdb.originalLanguage,
                                originalTitle: tmdb.originalTitle,
                                overview: tmdb.overview,
                                popularity: tmdb.popularity,
                                releaseDate: tmdb.releaseDate,
                                firstAirDate: nil,
                                title: tmdb.title,
                                name: nil,
                                originCountry: nil,
                                originalName: nil,
                                video: tmdb.video ?? false,
                                voteAverage: tmdb.voteAverage,
                                voteCount: tmdb.voteCount,
                                mediaType: "movie",
                                mediaInfo: seerr?.mediaInfo  // Use Seerr mediaInfo with status
                            ))
                        } else {
                            // Fetch from both TMDB (for poster) and Seerr (for status) in parallel
                            async let tmdbDetails = tmdbService.getTVDetails(id: tmdbId)
                            async let seerrDetails = try? seerrService.getTVDetails(id: tmdbId)

                            let (tmdb, seerr) = try await (tmdbDetails, seerrDetails)
                            print("✅ Fetched TV: \(tmdb.name) - posterPath: \(tmdb.posterPath ?? "nil")")

                            return MediaResult.tv(TVResult(
                                id: tmdb.id,
                                backdropPath: tmdb.backdropPath,
                                posterPath: tmdb.posterPath,  // Use TMDB posterPath
                                genreIds: tmdb.genres?.map { $0.id },
                                originalLanguage: tmdb.originalLanguage,
                                originalName: tmdb.originalName,
                                overview: tmdb.overview,
                                popularity: tmdb.popularity,
                                firstAirDate: tmdb.firstAirDate,
                                name: tmdb.name,
                                voteAverage: tmdb.voteAverage,
                                voteCount: tmdb.voteCount,
                                originCountry: tmdb.originCountry,
                                mediaType: "tv",
                                mediaInfo: seerr?.mediaInfo  // Use Seerr mediaInfo with status
                            ))
                        }
                    } catch {
                        print("❌ Failed to fetch details for \(item.title): \(error)")

                        // Create basic MediaResult as fallback
                        if item.mediaTypeEnum == .movie {
                            return MediaResult.movie(MovieResult(
                                id: tmdbId,
                                adult: nil,
                                backdropPath: nil,
                                posterPath: nil,
                                genreIds: nil,
                                originalLanguage: nil,
                                originalTitle: nil,
                                overview: nil,
                                popularity: nil,
                                releaseDate: nil,
                                firstAirDate: nil,
                                title: item.title,
                                name: nil,
                                originCountry: nil,
                                originalName: nil,
                                video: nil,
                                voteAverage: nil,
                                voteCount: nil,
                                mediaType: "movie",
                                mediaInfo: nil
                            ))
                        } else {
                            return MediaResult.tv(TVResult(
                                id: tmdbId,
                                backdropPath: nil,
                                posterPath: nil,
                                genreIds: nil,
                                originalLanguage: nil,
                                originalName: nil,
                                overview: nil,
                                popularity: nil,
                                firstAirDate: nil,
                                name: item.title,
                                voteAverage: nil,
                                voteCount: nil,
                                originCountry: nil,
                                mediaType: "tv",
                                mediaInfo: nil
                            ))
                        }
                    }
                }
            }

            var collectedResults: [MediaResult] = []
            for await result in group {
                if let result = result {
                    collectedResults.append(result)
                }
            }
            return collectedResults
        }

        print("🎬 ProfileView: Fetched \(results.count) watchlist items with details")
        return results
    }

    /// Enrich requests with TMDB data (backdrop/poster paths)
    private func enrichRequestsWithTMDB(requests: [MediaRequest]) async -> [MediaRequest] {
        print("🎬 ProfileView: Enriching \(requests.count) requests with TMDB data")

        let tmdbService = TMDBService.shared

        let enrichedRequests = await withTaskGroup(of: (Int, MediaInfo?)?.self) { group in
            for request in requests {
                guard let media = request.media else { continue }

                group.addTask {
                    do {
                        if media.mediaType == .movie {
                            let tmdbDetails = try await tmdbService.getMovieDetails(id: media.tmdbId)
                            print("✅ Fetched TMDB movie: \(tmdbDetails.title) - backdrop: \(tmdbDetails.backdropPath ?? "nil"), poster: \(tmdbDetails.posterPath ?? "nil")")

                            // Create enriched MediaInfo with TMDB backdrop/poster
                            let enrichedMedia = MediaInfo(
                                id: media.id,
                                tmdbId: media.tmdbId,
                                tvdbId: media.tvdbId,
                                status: media.status,
                                status4k: media.status4k,
                                requests: media.requests,
                                createdAt: media.createdAt,
                                updatedAt: media.updatedAt,
                                plexUrl: media.plexUrl,
                                jellyfinMediaId: media.jellyfinMediaId,
                                mediaAddedAt: media.mediaAddedAt,
                                mediaType: media.mediaType,
                                title: media.title ?? tmdbDetails.title,
                                originalTitle: media.originalTitle ?? tmdbDetails.originalTitle,
                                overview: media.overview ?? tmdbDetails.overview,
                                posterPath: tmdbDetails.posterPath,
                                backdropPath: tmdbDetails.backdropPath,
                                releaseDate: media.releaseDate ?? tmdbDetails.releaseDate,
                                firstAirDate: media.firstAirDate,
                                voteAverage: media.voteAverage ?? tmdbDetails.voteAverage,
                                voteCount: media.voteCount ?? tmdbDetails.voteCount,
                                popularity: media.popularity ?? tmdbDetails.popularity,
                                genres: media.genres ?? tmdbDetails.genres?.map { Genre(id: $0.id, name: $0.name, backdrops: nil) },
                                originalLanguage: media.originalLanguage ?? tmdbDetails.originalLanguage,
                                originCountry: media.originCountry
                            )
                            return (request.id, enrichedMedia)
                        } else {
                            let tmdbDetails = try await tmdbService.getTVDetails(id: media.tmdbId)
                            print("✅ Fetched TMDB TV: \(tmdbDetails.name) - backdrop: \(tmdbDetails.backdropPath ?? "nil"), poster: \(tmdbDetails.posterPath ?? "nil")")

                            // Create enriched MediaInfo with TMDB backdrop/poster
                            let enrichedMedia = MediaInfo(
                                id: media.id,
                                tmdbId: media.tmdbId,
                                tvdbId: media.tvdbId,
                                status: media.status,
                                status4k: media.status4k,
                                requests: media.requests,
                                createdAt: media.createdAt,
                                updatedAt: media.updatedAt,
                                plexUrl: media.plexUrl,
                                jellyfinMediaId: media.jellyfinMediaId,
                                mediaAddedAt: media.mediaAddedAt,
                                mediaType: media.mediaType,
                                title: media.title ?? tmdbDetails.name,
                                originalTitle: media.originalTitle ?? tmdbDetails.originalName,
                                overview: media.overview ?? tmdbDetails.overview,
                                posterPath: tmdbDetails.posterPath,
                                backdropPath: tmdbDetails.backdropPath,
                                releaseDate: media.releaseDate,
                                firstAirDate: media.firstAirDate ?? tmdbDetails.firstAirDate,
                                voteAverage: media.voteAverage ?? tmdbDetails.voteAverage,
                                voteCount: media.voteCount ?? tmdbDetails.voteCount,
                                popularity: media.popularity ?? tmdbDetails.popularity,
                                genres: media.genres ?? tmdbDetails.genres?.map { Genre(id: $0.id, name: $0.name, backdrops: nil) },
                                originalLanguage: media.originalLanguage ?? tmdbDetails.originalLanguage,
                                originCountry: media.originCountry ?? tmdbDetails.originCountry
                            )
                            return (request.id, enrichedMedia)
                        }
                    } catch {
                        print("❌ Failed to fetch TMDB details for request \(request.id): \(error)")
                        return nil
                    }
                }
            }

            // Collect results into dictionary
            var mediaMap: [Int: MediaInfo] = [:]
            for await result in group {
                if let (requestId, enrichedMedia) = result {
                    mediaMap[requestId] = enrichedMedia
                }
            }

            // Rebuild requests with enriched media
            return requests.map { request in
                if let enrichedMedia = mediaMap[request.id] {
                    return MediaRequest(
                        id: request.id,
                        status: request.status,
                        media: enrichedMedia,
                        createdAt: request.createdAt,
                        updatedAt: request.updatedAt,
                        requestedBy: request.requestedBy,
                        modifiedBy: request.modifiedBy,
                        is4k: request.is4k,
                        serverId: request.serverId,
                        profileId: request.profileId,
                        rootFolder: request.rootFolder
                    )
                } else {
                    return request
                }
            }
        }

        print("🎬 ProfileView: Enriched \(enrichedRequests.count) requests")
        return enrichedRequests
    }
}

#Preview {
    ProfileView()
        .environmentObject(ConfigManager())
}
