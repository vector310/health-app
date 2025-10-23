//
//  CalorieBalanceCalculator.swift
//  HealthTracker
//
//  Calculates calorie surplus/deficit based on intake and expenditure
//

import Foundation

struct CalorieBalanceCalculator {

    /// User profile for BMR calculation
    struct UserProfile: Codable {
        let weightKg: Double
        let heightCm: Double
        let age: Int
        let sex: Sex

        enum Sex: String, Codable {
            case male
            case female
        }
    }

    /// Daily calorie balance result
    struct DailyBalance {
        let intake: Int
        let bmr: Int
        let activeCalories: Int
        let totalExpenditure: Int
        let balance: Int // Positive = surplus, negative = deficit

        var isDeficit: Bool { balance < 0 }
        var isSurplus: Bool { balance > 0 }
        var isMaintenance: Bool { abs(balance) <= 200 }
    }

    /// Calculate BMR using Mifflin-St Jeor equation
    /// - Parameter profile: User profile with weight, height, age, sex
    /// - Returns: Basal Metabolic Rate in calories/day
    static func calculateBMR(profile: UserProfile) -> Int {
        let bmr: Double

        switch profile.sex {
        case .male:
            bmr = 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * Double(profile.age) + 5
        case .female:
            bmr = 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * Double(profile.age) - 161
        }

        return Int(bmr.rounded())
    }

    /// Calculate daily calorie balance
    /// - Parameters:
    ///   - caloriesConsumed: Total calories eaten
    ///   - activeCalories: Calories burned from activity (from HealthKit)
    ///   - profile: User profile for BMR calculation
    /// - Returns: DailyBalance with surplus/deficit
    static func calculateDailyBalance(
        caloriesConsumed: Int,
        activeCalories: Int,
        profile: UserProfile
    ) -> DailyBalance {
        let bmr = calculateBMR(profile: profile)
        let totalExpenditure = bmr + activeCalories
        let balance = caloriesConsumed - totalExpenditure

        return DailyBalance(
            intake: caloriesConsumed,
            bmr: bmr,
            activeCalories: activeCalories,
            totalExpenditure: totalExpenditure,
            balance: balance
        )
    }

    /// Calculate weekly average balance
    /// - Parameter dailyBalances: Array of daily balance results
    /// - Returns: Average daily surplus/deficit for the week
    static func calculateWeeklyAverage(dailyBalances: [DailyBalance]) -> Double {
        guard !dailyBalances.isEmpty else { return 0 }
        let sum = dailyBalances.reduce(0) { $0 + $1.balance }
        return Double(sum) / Double(dailyBalances.count)
    }

    /// Format balance for display
    /// - Parameter balance: The balance in calories
    /// - Returns: Formatted string like "+250 cal" or "-350 cal"
    static func formatBalance(_ balance: Int) -> String {
        let sign = balance >= 0 ? "+" : ""
        return "\(sign)\(balance) cal"
    }

    /// Get color indicator for balance
    /// - Parameter balance: The balance in calories
    /// - Returns: Color name: "green" (surplus), "red" (deficit), "yellow" (maintenance)
    static func balanceColor(_ balance: Int) -> String {
        if balance > 200 { return "green" }
        if balance < -200 { return "red" }
        return "yellow"
    }
}
