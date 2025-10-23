/**
 * Health metric calculations (phase detection, BMR, etc.)
 */

export type Phase = 'cut' | 'maintenance' | 'bulk';

export interface PhaseSuggestion {
  suggestedPhase: Phase;
  confidence: number;
  reasoning: string;
  calorieBalance: number;
  weightTrend: number;
}

/**
 * Suggest a phase based on calorie balance and weight trend
 */
export function suggestPhase(avgDailySurplus: number, avgWeeklyWeightChange: number): PhaseSuggestion {
  const scores: Record<Phase, number> = { cut: 0, maintenance: 0, bulk: 0 };

  // Score based on calorie balance
  if (avgDailySurplus < -300) {
    scores.cut += 1.0;
  } else if (avgDailySurplus > 300) {
    scores.bulk += 1.0;
  } else {
    scores.maintenance += 1.0;
    if (avgDailySurplus < -200) {
      scores.cut += 0.5;
    } else if (avgDailySurplus > 200) {
      scores.bulk += 0.5;
    }
  }

  // Score based on weight trend
  if (avgWeeklyWeightChange < -0.5) {
    scores.cut += 1.0;
  } else if (avgWeeklyWeightChange > 0.5) {
    scores.bulk += 1.0;
  } else {
    scores.maintenance += 1.0;
    if (avgWeeklyWeightChange < -0.3) {
      scores.cut += 0.5;
    } else if (avgWeeklyWeightChange > 0.3) {
      scores.bulk += 0.5;
    }
  }

  // Find highest scoring phase
  const entries = Object.entries(scores) as [Phase, number][];
  entries.sort((a, b) => b[1] - a[1]);

  const suggestedPhase = entries[0][0];
  const maxScore = entries[0][1];
  const confidence = maxScore / 2.0; // Normalize to 0-1

  const reasoning = generateReasoning(suggestedPhase, avgDailySurplus, avgWeeklyWeightChange);

  return {
    suggestedPhase,
    confidence,
    reasoning,
    calorieBalance: avgDailySurplus,
    weightTrend: avgWeeklyWeightChange,
  };
}

function generateReasoning(phase: Phase, calorieBalance: number, weightTrend: number): string {
  const calorieDesc = calorieBalance < -200 ? 'deficit' : calorieBalance > 200 ? 'surplus' : 'balanced';
  const weightDesc = weightTrend < -0.3 ? 'losing' : weightTrend > 0.3 ? 'gaining' : 'maintaining';

  switch (phase) {
    case 'cut':
      return `In a calorie ${calorieDesc}, ${weightDesc} weight. Suggests cutting phase.`;
    case 'maintenance':
      return `Calories ${calorieDesc}, weight ${weightDesc}. Suggests maintenance.`;
    case 'bulk':
      return `In a calorie ${calorieDesc}, ${weightDesc} weight. Suggests bulking phase.`;
  }
}

/**
 * Calculate BMR using Mifflin-St Jeor equation
 */
export function calculateBMR(weightKg: number, heightCm: number, age: number, sex: 'male' | 'female'): number {
  let bmr = 10 * weightKg + 6.25 * heightCm - 5 * age;

  if (sex === 'male') {
    bmr += 5;
  } else {
    bmr -= 161;
  }

  return Math.round(bmr);
}

/**
 * Calculate daily calorie balance
 */
export function calculateDailyBalance(
  caloriesConsumed: number,
  activeCalories: number,
  bmr: number
): {
  balance: number;
  totalExpenditure: number;
} {
  const totalExpenditure = bmr + activeCalories;
  const balance = caloriesConsumed - totalExpenditure;

  return { balance, totalExpenditure };
}

/**
 * Format weight change for display
 */
export function formatWeightChange(change: number): string {
  const sign = change >= 0 ? '+' : '';
  return `${sign}${change.toFixed(1)} lbs`;
}

/**
 * Format percentage change
 */
export function formatPercentageChange(change: number): string {
  const sign = change >= 0 ? '+' : '';
  return `${sign}${change.toFixed(1)}%`;
}
