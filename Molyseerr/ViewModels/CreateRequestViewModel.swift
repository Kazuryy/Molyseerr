//
//  CreateRequestViewModel.swift
//  Molyseerr
//
//  Created by Claude on 28/12/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class CreateRequestViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var mediaType: MediaType
    @Published var mediaId: Int
    @Published var selectedSeasons: Set<Int> = []
    @Published var allSeasons: [Season] = []
    @Published var is4K: Bool = false
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?

    // MARK: - Initialization
    init(mediaType: MediaType, mediaId: Int, seasons: [Season] = []) {
        self.mediaType = mediaType
        self.mediaId = mediaId
        self.allSeasons = seasons.filter { $0.seasonNumber > 0 } // Exclude season 0 (specials)
    }

    // MARK: - Computed Properties
    var canSubmit: Bool {
        if mediaType == .tv {
            return !selectedSeasons.isEmpty && !isSubmitting
        }
        return !isSubmitting
    }

    var areAllSeasonsSelected: Bool {
        guard !allSeasons.isEmpty else { return false }
        return selectedSeasons.count == allSeasons.count
    }

    // MARK: - Season Selection
    func toggleSeason(_ seasonNumber: Int) {
        if selectedSeasons.contains(seasonNumber) {
            selectedSeasons.remove(seasonNumber)
        } else {
            selectedSeasons.insert(seasonNumber)
        }
    }

    func selectAllSeasons() {
        selectedSeasons = Set(allSeasons.map { $0.seasonNumber })
    }

    func deselectAllSeasons() {
        selectedSeasons.removeAll()
    }

    func toggleAllSeasons() {
        if areAllSeasonsSelected {
            deselectAllSeasons()
        } else {
            selectAllSeasons()
        }
    }

    // MARK: - Submit Request
    func submitRequest() async -> Bool {
        guard canSubmit else {
            return false
        }

        isSubmitting = true
        errorMessage = nil

        do {
            let requestBody = MediaRequestBody(
                mediaType: mediaType,
                mediaId: mediaId,
                seasons: mediaType == .tv ? Array(selectedSeasons).sorted() : nil,
                is4k: is4K ? true : nil,
                serverId: nil,
                profileId: nil,
                rootFolder: nil
            )

            _ = try await SeerrService.shared.createRequest(requestBody)
            isSubmitting = false
            return true
        } catch {
            errorMessage = "Failed to create request: \(error.localizedDescription)"
            isSubmitting = false
            return false
        }
    }
}
