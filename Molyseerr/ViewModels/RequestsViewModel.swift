//
//  RequestsViewModel.swift
//  Molyseerr
//
//  Created by Claude on 28/12/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class RequestsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var requests: [MediaRequest] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedFilter: RequestFilter = .all
    @Published var hasMorePages: Bool = true

    // MARK: - Private Properties
    private var currentPage: Int = 1
    private let pageSize: Int = 20
    private var totalPages: Int = 1

    // MARK: - Fetch Requests
    func fetchRequests(refresh: Bool = false) async {
        if refresh {
            currentPage = 1
            requests.removeAll()
        }

        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let response = try await SeerrService.shared.getRequestList(
                filter: selectedFilter.rawValue,
                sort: "added",
                take: pageSize,
                skip: (currentPage - 1) * pageSize
            )

            // Update requests list
            if refresh {
                requests = response.results
            } else {
                requests.append(contentsOf: response.results)
            }

            // Update pagination info
            totalPages = response.pageInfo.pages
            hasMorePages = currentPage < totalPages

            isLoading = false
        } catch {
            errorMessage = "Failed to load requests: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Load More (Pagination)
    func loadMore() async {
        guard hasMorePages, !isLoading else { return }
        currentPage += 1
        await fetchRequests()
    }

    // MARK: - Refresh
    func refresh() async {
        await fetchRequests(refresh: true)
    }

    // MARK: - Apply Filter
    func applyFilter(_ filter: RequestFilter) async {
        guard selectedFilter != filter else { return }
        selectedFilter = filter
        await fetchRequests(refresh: true)
    }

    // MARK: - Cancel Request
    func cancelRequest(id: Int) async -> Bool {
        do {
            try await SeerrService.shared.deleteRequest(id: id)
            // Remove from local list
            requests.removeAll { $0.id == id }
            return true
        } catch {
            errorMessage = "Failed to cancel request: \(error.localizedDescription)"
            return false
        }
    }
}
