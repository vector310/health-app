//
//  APIService.swift
//  HealthTracker
//
//  HTTP client for MCP server API communication
//

import Foundation
import Combine

@MainActor
class APIService: ObservableObject {

    // API Configuration
    private var baseURL: String
    private var apiKey: String

    @Published var isConnected = false
    @Published var lastSyncDate: Date?

    init(baseURL: String = "", apiKey: String = "") {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    // MARK: - Configuration

    func configure(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    // MARK: - Week Operations

    /// Create or update a week record
    func saveWeek(_ week: WeekRecord) async throws {
        let endpoint = "/api/weeks"
        try await post(endpoint: endpoint, body: week)
    }

    /// Get a specific week by start date
    func getWeek(startDate: Date) async throws -> WeekRecord? {
        let dateString = ISO8601DateFormatter().string(from: startDate)
        let endpoint = "/api/weeks/\(dateString)"
        return try await get(endpoint: endpoint)
    }

    /// Get current in-progress week
    func getCurrentWeek() async throws -> WeekRecord? {
        let endpoint = "/api/current-week"
        return try await get(endpoint: endpoint)
    }

    /// Get list of completed weeks
    func getWeeks(limit: Int = 6, offset: Int = 0) async throws -> [WeekRecord] {
        let endpoint = "/api/weeks?limit=\(limit)&offset=\(offset)"
        return try await get(endpoint: endpoint) ?? []
    }

    /// Update weekly targets
    func updateTargets(weekId: UUID, targets: WeekTargets) async throws {
        let endpoint = "/api/weeks/\(weekId.uuidString)/targets"
        try await put(endpoint: endpoint, body: targets)
    }

    // MARK: - Weight Operations

    /// Save a weight reading
    func saveWeightReading(_ reading: WeightReading) async throws {
        let endpoint = "/api/weight"
        try await post(endpoint: endpoint, body: reading)
    }

    /// Get weight readings for a date range
    func getWeightReadings(from startDate: Date, to endDate: Date) async throws -> [WeightReading] {
        let formatter = ISO8601DateFormatter()
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        let endpoint = "/api/weight?start=\(start)&end=\(end)"
        return try await get(endpoint: endpoint) ?? []
    }

    /// Get rolling weight average
    func getRollingAverage(date: Date, windowDays: Int = 7) async throws -> Double? {
        let dateString = ISO8601DateFormatter().string(from: date)
        let endpoint = "/api/weight/average?date=\(dateString)&window=\(windowDays)"
        let response: AverageResponse? = try await get(endpoint: endpoint)
        return response?.average
    }

    // MARK: - Daily Metrics Operations

    /// Save daily metrics
    func saveDailyMetrics(_ metrics: DailyMetrics) async throws {
        let endpoint = "/api/daily-metrics"
        try await post(endpoint: endpoint, body: metrics)
    }

    // MARK: - Health Check

    /// Check server health
    func healthCheck() async throws -> Bool {
        let endpoint = "/api/health"
        let response: HealthResponse? = try await get(endpoint: endpoint)
        let healthy = response?.status == "ok"
        isConnected = healthy
        if healthy {
            lastSyncDate = Date()
        }
        return healthy
    }

    // MARK: - HTTP Methods

    private func get<T: Decodable>(endpoint: String) async throws -> T? {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Handle empty responses
        if data.isEmpty {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    private func post<T: Encodable>(endpoint: String, body: T) async throws {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    private func put<T: Encodable>(endpoint: String, body: T) async throws {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    private func buildURL(endpoint: String) throws -> URL {
        guard !baseURL.isEmpty else {
            throw APIError.notConfigured
        }

        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        return url
    }
}

// MARK: - Supporting Types

struct WeekTargets: Codable {
    let targetCalories: Int
    let targetProtein: Int
    let targetSteps: Int
    let targetCardio: Int
    let phase: Phase
}

struct AverageResponse: Codable {
    let average: Double?
    let confidence: Double
    let readingCount: Int
}

struct HealthResponse: Codable {
    let status: String
}

// MARK: - Errors

enum APIError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "API not configured. Please enter your server URL and API key in Settings."
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            if statusCode == 401 || statusCode == 403 {
                return "Authentication failed. Please check your API key."
            }
            return "Server error: \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
