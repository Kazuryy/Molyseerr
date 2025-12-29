import SwiftUI
import Combine

struct RecentRequestsRow: View {
    @StateObject private var viewModel = RecentRequestsViewModel()
    @Namespace private var requestsNamespace
    @FocusState private var focusedRequestId: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text("Recent Requests")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                // View All button
                NavigationLink {
                    RequestsView()
                } label: {
                    HStack(spacing: 8) {
                        Text("View All")
                            .font(.headline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 48)

            // Horizontal scroll of request cards
            if viewModel.isLoading && viewModel.requests.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 40) {
                        ForEach(0..<3, id: \.self) { _ in
                            RequestCardPlaceholder()
                        }
                    }
                    .padding(.horizontal, 48)
                    .padding(.vertical, 30)
                }
            } else if let errorMessage = viewModel.errorMessage {
                Text("Error loading requests: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding(.horizontal, 48)
            } else if viewModel.requests.isEmpty {
                Text("No recent requests")
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 48)
                    .padding(.vertical, 30)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 40) {
                        ForEach(viewModel.requests, id: \.id) { request in
                            if let media = request.media {
                                RequestDiscoverCard(
                                    request: request,
                                    title: viewModel.mediaTitles[media.tmdbId],
                                    posterPath: viewModel.mediaPosters[media.tmdbId],
                                    backdropPath: viewModel.mediaBackdrops[media.tmdbId]
                                )
                                .focused($focusedRequestId, equals: request.id)
                                .id(request.id)
                            }
                        }
                    }
                    .padding(.horizontal, 48)
                    .padding(.vertical, 30)
                }
            }
        }
        .task {
            await viewModel.fetchRecentRequests()
        }
    }
}

// Placeholder card for loading state
struct RequestCardPlaceholder: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 384, height: 216)
                .cornerRadius(16)
                .shimmering()
        }
    }
}

// Shimmering effect for loading state
extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase)
                    .mask(content)
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

// ViewModel for fetching recent requests
@MainActor
class RecentRequestsViewModel: ObservableObject {
    @Published var requests: [MediaRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var mediaTitles: [Int: String] = [:]
    @Published var mediaPosters: [Int: String] = [:]
    @Published var mediaBackdrops: [Int: String] = [:]

    func fetchRecentRequests() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch recent requests (last 10)
            let requestList = try await SeerrService.shared.getRequestList(
                filter: "all",
                sort: "modified",
                take: 10,
                skip: 0
            )

            requests = requestList.results

            // Fetch titles, posters, and backdrops for requests that don't have them
            await fetchMissingTitlesAndPosters()

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func fetchMissingTitlesAndPosters() async {
        await withTaskGroup(of: (Int, String?, String?, String?).self) { group in
            for request in requests {
                guard let media = request.media else { continue }
                let tmdbId = media.tmdbId
                let mediaType = media.mediaType ?? .movie  // Default to movie if nil

                // Only fetch if we don't have the title
                if mediaTitles[tmdbId] == nil {
                    group.addTask {
                        do {
                            if mediaType == .movie {
                                let movie = try await TMDBService.shared.getMovieDetails(id: tmdbId)
                                return (tmdbId, movie.title, movie.posterPath, movie.backdropPath)
                            } else {
                                let tvShow = try await TMDBService.shared.getTVDetails(id: tmdbId)
                                return (tmdbId, tvShow.name, tvShow.posterPath, tvShow.backdropPath)
                            }
                        } catch {
                            print("Error fetching title for TMDB ID \(tmdbId): \(error)")
                            return (tmdbId, nil, nil, nil)
                        }
                    }
                }
            }

            for await (tmdbId, title, posterPath, backdropPath) in group {
                if let title = title {
                    mediaTitles[tmdbId] = title
                }
                if let posterPath = posterPath {
                    mediaPosters[tmdbId] = posterPath
                }
                if let backdropPath = backdropPath {
                    mediaBackdrops[tmdbId] = backdropPath
                }
            }
        }
    }
}
