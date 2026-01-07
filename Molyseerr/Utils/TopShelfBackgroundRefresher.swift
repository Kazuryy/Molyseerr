//
//  TopShelfBackgroundRefresher.swift
//  Molyseerr
//
//  Created by Claude on 06/01/2026.
//

import Foundation
import UIKit

/// Background task manager for TopShelf cache refresh
/// Proactively refreshes TopShelf content while the app is active to ensure instant loading
@MainActor
class TopShelfBackgroundRefresher {

    // MARK: - Singleton

    static let shared = TopShelfBackgroundRefresher()

    // MARK: - Properties

    private var refreshTimer: Timer?
    private let settings = TopShelfSettings.shared
    private var isRefreshing = false

    // Refresh intervals
    private let autoRefreshInterval: TimeInterval = 10 * 60 // 10 minutes
    private let staleThreshold: TimeInterval = 12 * 60 // 12 minutes (before 15min TTL)

    // MARK: - Initialization

    private init() {
        setupBackgroundRefresh()
    }

    // MARK: - Public Methods

    /// Start automatic background refresh
    func startAutoRefresh() {
        stopAutoRefresh() // Clear existing timer

        print("🔄 Starting TopShelf background refresh (every \(Int(autoRefreshInterval/60)) minutes)")

        // Immediate check
        Task {
            await refreshIfNeeded()
        }

        // Schedule periodic refresh
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: autoRefreshInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshIfNeeded()
            }
        }
    }

    /// Stop automatic background refresh
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        print("⏹️ Stopped TopShelf background refresh")
    }

    /// Force refresh cache immediately (for manual triggers)
    func forceRefresh() async {
        print("🔄 Force refreshing TopShelf cache...")
        await performRefresh()
    }

    // MARK: - Private Methods

    /// Setup background refresh notifications
    private func setupBackgroundRefresh() {
        // Refresh when app becomes active
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📱 APP BECAME ACTIVE at \(timestamp)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            Task { @MainActor in
                await self?.refreshIfNeeded()
            }
        }

        // Stop refresh when app goes to background
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📱 APP ENTERING BACKGROUND at \(timestamp)")
            print("⏱️ TopShelf extension should load next...")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            Task { @MainActor in
                // Final refresh before going to background to ensure fresh cache
                await self?.performFinalRefresh()
            }
        }
    }

    /// Check if refresh is needed and perform if necessary
    private func refreshIfNeeded() async {
        // Skip if already refreshing
        guard !isRefreshing else {
            print("⏭️ Refresh already in progress, skipping")
            return
        }

        // Skip if no sliders selected
        guard !settings.selectedSliders.isEmpty else {
            print("⏭️ No sliders selected, skipping refresh")
            return
        }

        // Check if cache is approaching stale threshold
        if let timestamp = settings.cacheTimestamp {
            let age = Date().timeIntervalSince(timestamp)

            if age > staleThreshold {
                print("⚠️ Cache is \(Int(age/60))min old (threshold: \(Int(staleThreshold/60))min), refreshing...")
                await performRefresh()
            } else {
                print("✅ Cache is fresh (\(Int(age/60))min old), no refresh needed")
            }
        } else {
            // No cache timestamp - refresh immediately
            print("🔄 No cache timestamp found, performing initial refresh...")
            await performRefresh()
        }
    }

    /// Perform final refresh before app goes to background
    private func performFinalRefresh() async {
        // Only refresh if cache is stale
        if settings.isCacheStale {
            print("🔄 App going to background - refreshing stale cache...")
            await performRefresh()
        } else {
            print("✅ Cache is fresh, no pre-background refresh needed")
        }
    }

    /// Perform the actual cache refresh
    private func performRefresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        let startTime = Date()
        print("🚀 Starting background TopShelf refresh...")

        do {
            // Create a temporary view model instance to use existing refresh logic
            let viewModel = TopShelfConfigViewModel()

            // Wait for sliders to load
            await viewModel.loadSliders()

            // Refresh all selected sliders
            await viewModel.refreshAllSliders()

            let duration = Date().timeIntervalSince(startTime)
            print("✅ Background refresh completed in \(String(format: "%.2f", duration))s")

        } catch {
            print("❌ Background refresh failed: \(error)")
        }
    }

    // MARK: - Deinitialization

    deinit {
        NotificationCenter.default.removeObserver(self)
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
