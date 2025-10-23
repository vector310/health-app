//
//  PhaseDetector.swift
//  HealthTracker
//
//  Suggests training phase based on calorie balance and weight trends
//

import Foundation

struct PhaseDetector {

    /// Phase suggestion result
    struct PhaseSuggestion {
        let suggestedPhase: Phase
        let confidence: Double // 0.0 to 1.0
        let reasoning: String
        let calorieBalance: Double // Average daily surplus/deficit
        let weightTrend: Double // Average weekly change in lbs
    }

    /// Suggest a phase based on calorie balance and weight trend
    /// - Parameters:
    ///   - avgDailySurplus: Average daily calorie surplus (negative = deficit)
    ///   - avgWeeklyWeightChange: Average weekly weight change in pounds
    /// - Returns: PhaseSuggestion with recommended phase and reasoning
    static func suggestPhase(
        avgDailySurplus: Double,
        avgWeeklyWeightChange: Double
    ) -> PhaseSuggestion {

        var scores: [Phase: Double] = [.cut: 0, .maintenance: 0, .bulk: 0]

        // Score based on calorie balance
        if avgDailySurplus < -300 {
            scores[.cut, default: 0] += 1.0
        } else if avgDailySurplus > 300 {
            scores[.bulk, default: 0] += 1.0
        } else {
            scores[.maintenance, default: 0] += 1.0
            // Partial scores for borderline cases
            if avgDailySurplus < -200 {
                scores[.cut, default: 0] += 0.5
            } else if avgDailySurplus > 200 {
                scores[.bulk, default: 0] += 0.5
            }
        }

        // Score based on weight trend
        if avgWeeklyWeightChange < -0.5 {
            scores[.cut, default: 0] += 1.0
        } else if avgWeeklyWeightChange > 0.5 {
            scores[.bulk, default: 0] += 1.0
        } else {
            scores[.maintenance, default: 0] += 1.0
            // Partial scores for borderline cases
            if avgWeeklyWeightChange < -0.3 {
                scores[.cut, default: 0] += 0.5
            } else if avgWeeklyWeightChange > 0.3 {
                scores[.bulk, default: 0] += 0.5
            }
        }

        // Find highest scoring phase
        let sortedScores = scores.sorted { $0.value > $1.value }
        let suggestedPhase = sortedScores.first?.key ?? .maintenance
        let maxScore = sortedScores.first?.value ?? 0
        let confidence = maxScore / 2.0 // Normalize to 0-1 (max score is 2)

        // Generate reasoning
        let reasoning = generateReasoning(
            phase: suggestedPhase,
            calorieBalance: avgDailySurplus,
            weightTrend: avgWeeklyWeightChange
        )

        return PhaseSuggestion(
            suggestedPhase: suggestedPhase,
            confidence: confidence,
            reasoning: reasoning,
            calorieBalance: avgDailySurplus,
            weightTrend: avgWeeklyWeightChange
        )
    }

    /// Check if actual phase aligns with calorie/weight data
    /// - Parameters:
    ///   - actualPhase: The phase the user set
    ///   - avgDailySurplus: Average daily calorie surplus
    ///   - avgWeeklyWeightChange: Average weekly weight change
    /// - Returns: True if aligned, false if mismatched
    static func isPhaseAligned(
        actualPhase: Phase,
        avgDailySurplus: Double,
        avgWeeklyWeightChange: Double
    ) -> Bool {
        let suggestion = suggestPhase(
            avgDailySurplus: avgDailySurplus,
            avgWeeklyWeightChange: avgWeeklyWeightChange
        )
        return suggestion.suggestedPhase == actualPhase && suggestion.confidence > 0.5
    }

    // MARK: - Private Helpers

    private static func generateReasoning(
        phase: Phase,
        calorieBalance: Double,
        weightTrend: Double
    ) -> String {
        let calorieDesc = calorieBalance < -200 ? "deficit" : calorieBalance > 200 ? "surplus" : "balanced"
        let weightDesc = weightTrend < -0.3 ? "losing" : weightTrend > 0.3 ? "gaining" : "maintaining"

        switch phase {
        case .cut:
            return "In a calorie \(calorieDesc), \(weightDesc) weight. Suggests cutting phase."
        case .maintenance:
            return "Calories \(calorieDesc), weight \(weightDesc). Suggests maintenance."
        case .bulk:
            return "In a calorie \(calorieDesc), \(weightDesc) weight. Suggests bulking phase."
        }
    }
}
