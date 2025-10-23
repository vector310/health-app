//
//  HistoryViewModel.swift
//  HealthTracker
//
//  Manages historical weeks with pagination
//

import Foundation
import Combine
import SwiftUI

@MainActor
class HistoryViewModel: ObservableObject {

    var apiService: APIService
    var cacheManager: CacheManager

    @Published var weeks: [WeekRecord] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var hasMorePages = true

    private var currentOffset = 0
    private let pageSize = 6

    init(apiService: APIService, cacheManager: CacheManager) {
        self.apiService = apiService
        self.cacheManager = cacheManager
    }

    func loadWeeks() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        currentOffset = 0
        hasMorePages = true

        do {
            // Try cache first
            if let cachedWeeks = cacheManager.getCachedRecentWeeks() {
                weeks = cachedWeeks
            }

            // Fetch from server
            let fetchedWeeks = try await apiService.getWeeks(limit: pageSize, offset: 0)
            weeks = fetchedWeeks
            currentOffset = pageSize

            // Cache the results
            cacheManager.cacheRecentWeeks(fetchedWeeks)

            hasMorePages = fetchedWeeks.count == pageSize
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to load weeks: \(error.localizedDescription)"

            // Fall back to cached data
            if let cachedWeeks = cacheManager.getCachedRecentWeeks() {
                weeks = cachedWeeks
            }
        }
    }

    func loadMoreWeeks() async {
        guard !isLoadingMore && hasMorePages else { return }

        isLoadingMore = true

        do {
            let moreWeeks = try await apiService.getWeeks(limit: pageSize, offset: currentOffset)

            weeks.append(contentsOf: moreWeeks)
            currentOffset += pageSize
            hasMorePages = moreWeeks.count == pageSize

            isLoadingMore = false
        } catch {
            isLoadingMore = false
            errorMessage = "Failed to load more weeks: \(error.localizedDescription)"
        }
    }

    func refresh() async {
        await loadWeeks()
    }
}
