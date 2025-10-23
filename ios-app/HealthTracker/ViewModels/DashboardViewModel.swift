//
//  DashboardViewModel.swift
//  HealthTracker
//
//  Manages current week data and HealthKit synchronization
//

import Foundation
import Combine
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {

    // Dependencies
    var healthKitManager: HealthKitManager
    var apiService: APIService
    var cacheManager: CacheManager

    // Published state
    @Published var currentWeek: WeekRecord?
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var errorMessage: String?
    @Published var lastSyncDate: Date?

    // Current week metrics
    @Published var runningSteps: Int = 0
    @Published var runningCalories: Int = 0
    @Published var runningProtein: Int = 0
    @Published var runningCardio: Int = 0
    @Published var currentWeight: Double?
    @Published var sevenDayAverage: Double?

    init(
        healthKitManager: HealthKitManager,
        apiService: APIService,
        cacheManager: CacheManager
    ) {
        self.healthKitManager = healthKitManager
        self.apiService = apiService
        self.cacheManager = cacheManager
    }

    // MARK: - Public Methods

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Try to load from cache first
            if let cachedWeek = cacheManager.getCachedCurrentWeek() {
                currentWeek = cachedWeek
            }

            // Fetch fresh data from server
            if let serverWeek = try await apiService.getCurrentWeek() {
                currentWeek = serverWeek
                cacheManager.cacheCurrentWeek(serverWeek)
            } else {
                // No current week exists, create one
                await createCurrentWeek()
            }

            // Sync HealthKit data
            await syncHealthKitData()

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to load data: \(error.localizedDescription)"

            // Fall back to cached data if available
            if let cachedWeek = cacheManager.getCachedCurrentWeek() {
                currentWeek = cachedWeek
            }
        }
    }

    func refresh() async {
        isSyncing = true
        await syncHealthKitData()
        isSyncing = false
        lastSyncDate = Date()
    }

    // MARK: - HealthKit Sync

    private func syncHealthKitData() async {
        guard healthKitManager.isAuthorized else {
            errorMessage = "HealthKit access not authorized"
            return
        }

        let boundaries = DateHelpers.currentWeekBoundaries()
        let startDate = boundaries.start
        let endDate = boundaries.end

        do {
            // Fetch all metrics concurrently
            async let steps = healthKitManager.fetchSteps(from: startDate, to: Date())
            async let calories = healthKitManager.fetchCalories(from: startDate, to: Date())
            async let protein = healthKitManager.fetchProtein(from: startDate, to: Date())
            async let cardio = healthKitManager.fetchCardioCalories(from: startDate, to: Date())
            async let weightReadings = healthKitManager.fetchWeightReadings(from: startDate, to: Date())

            let (s, c, p, cc, readings) = try await (steps, calories, protein, cardio, weightReadings)

            // Update running totals
            runningSteps = s
            runningCalories = c
            runningProtein = p
            runningCardio = cc

            // Calculate 7-day weight average
            if !readings.isEmpty {
                currentWeight = readings.last?.weight
                let avgResult = WeightAverageCalculator.calculate7DayAverage(from: readings)
                sevenDayAverage = avgResult.average
            }

            // Update current week record
            if var week = currentWeek {
                week.totalSteps = s
                week.totalCalories = c
                week.totalProtein = p
                week.totalCardioCalories = cc
                week.averageWeight = sevenDayAverage
                week.bodyFatPercentage = readings.last?.bodyFatPercentage
                week.muscleMassPercentage = readings.last?.muscleMassPercentage

                // Save to server and cache
                try await apiService.saveWeek(week)
                cacheManager.cacheCurrentWeek(week)
                currentWeek = week
            }

        } catch {
            errorMessage = "Failed to sync HealthKit data: \(error.localizedDescription)"
        }
    }

    // MARK: - Week Management

    private func createCurrentWeek() async {
        let boundaries = DateHelpers.currentWeekBoundaries()

        // Get previous week's targets if available
        let previousBoundaries = DateHelpers.weekBoundaries(weeksAgo: 1)
        let previousWeek = try? await apiService.getWeek(startDate: previousBoundaries.start)

        // Create new week with carried-forward targets
        let newWeek = WeekRecord(
            startDate: boundaries.start,
            endDate: boundaries.end,
            targetCalories: previousWeek?.targetCalories ?? 14000,
            targetProtein: previousWeek?.targetProtein ?? 1000,
            targetSteps: previousWeek?.targetSteps ?? 70000,
            targetCardio: previousWeek?.targetCardio ?? 2000,
            phase: previousWeek?.phase ?? .maintenance
        )

        do {
            try await apiService.saveWeek(newWeek)
            currentWeek = newWeek
            cacheManager.cacheCurrentWeek(newWeek)
        } catch {
            errorMessage = "Failed to create new week: \(error.localizedDescription)"
        }
    }

    func updateTargets(calories: Int, protein: Int, steps: Int, cardio: Int, phase: Phase) async {
        guard var week = currentWeek else { return }

        week.targetCalories = calories
        week.targetProtein = protein
        week.targetSteps = steps
        week.targetCardio = cardio
        week.phase = phase

        do {
            try await apiService.saveWeek(week)
            currentWeek = week
            cacheManager.cacheCurrentWeek(week)
        } catch {
            errorMessage = "Failed to update targets: \(error.localizedDescription)"
        }
    }

    // MARK: - Computed Properties

    var daysIntoWeek: Int {
        guard let week = currentWeek else { return 0 }
        return Calendar.current.dateComponents([.day], from: week.startDate, to: Date()).day ?? 0 + 1
    }

    var isCheckInTime: Bool {
        DateHelpers.isCheckInTime()
    }
}
