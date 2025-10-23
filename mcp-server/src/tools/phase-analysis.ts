/**
 * MCP Tool: Analyze phases
 */

import { D1Database } from '@cloudflare/workers-types';
import { getWeeks } from '../db/queries';
import { suggestPhase } from '../utils/calculations';

export const phaseAnalysisTool = {
  name: 'analyze_phases',
  description: 'Analyze training phases over a date range, showing effectiveness and recommendations',
  inputSchema: {
    type: 'object',
    properties: {
      startDate: {
        type: 'string',
        description: 'Start date in ISO format (YYYY-MM-DD)',
      },
      endDate: {
        type: 'string',
        description: 'End date in ISO format (YYYY-MM-DD)',
      },
    },
    required: ['startDate', 'endDate'],
  },
};

export async function executePhaseAnalysis(db: D1Database, args: { startDate: string; endDate: string }) {
  // Get all weeks in the date range
  const allWeeks = await getWeeks(db, 100, 0); // Get up to 100 weeks

  // Filter to date range
  const weeks = allWeeks.filter((w) => w.start_date >= args.startDate && w.start_date <= args.endDate);

  if (weeks.length === 0) {
    return {
      content: [
        {
          type: 'text',
          text: `No weeks found between ${args.startDate} and ${args.endDate}`,
        },
      ],
    };
  }

  // Group by phase
  const phaseGroups: Record<string, typeof weeks> = {};
  weeks.forEach((week) => {
    if (!phaseGroups[week.phase]) {
      phaseGroups[week.phase] = [];
    }
    phaseGroups[week.phase].push(week);
  });

  let text = `Phase Analysis (${args.startDate} to ${args.endDate})\n\n`;
  text += `Total weeks analyzed: ${weeks.length}\n\n`;

  // Analyze each phase
  Object.entries(phaseGroups).forEach(([phase, phaseWeeks]) => {
    text += `${phase.toUpperCase()} PHASE (${phaseWeeks.length} weeks)\n`;
    text += `${'='.repeat(40)}\n`;

    // Calculate averages
    const validWeeks = phaseWeeks.filter(
      (w) => w.average_weight != null && w.week_over_week_weight_change != null
    );

    if (validWeeks.length > 0) {
      const avgWeightChange =
        validWeeks.reduce((sum, w) => sum + (w.week_over_week_weight_change || 0), 0) / validWeeks.length;

      const totalWeightChange =
        (validWeeks[validWeeks.length - 1].average_weight || 0) - (validWeeks[0].average_weight || 0);

      text += `Average weekly weight change: ${avgWeightChange >= 0 ? '+' : ''}${avgWeightChange.toFixed(2)} lbs\n`;
      text += `Total weight change: ${totalWeightChange >= 0 ? '+' : ''}${totalWeightChange.toFixed(1)} lbs\n`;

      // Body composition changes
      const firstWeek = validWeeks[0];
      const lastWeek = validWeeks[validWeeks.length - 1];

      if (firstWeek.body_fat_percentage && lastWeek.body_fat_percentage) {
        const bfChange = lastWeek.body_fat_percentage - firstWeek.body_fat_percentage;
        text += `Body fat change: ${bfChange >= 0 ? '+' : ''}${bfChange.toFixed(1)}%\n`;
      }

      if (firstWeek.muscle_mass_percentage && lastWeek.muscle_mass_percentage) {
        const mmChange = lastWeek.muscle_mass_percentage - firstWeek.muscle_mass_percentage;
        text += `Muscle mass change: ${mmChange >= 0 ? '+' : ''}${mmChange.toFixed(1)}%\n`;
      }

      // Adherence
      const weeksWithData = phaseWeeks.filter((w) => w.total_calories && w.total_steps && w.total_protein);
      if (weeksWithData.length > 0) {
        const avgCalAdherence =
          weeksWithData.reduce((sum, w) => sum + (w.total_calories! / w.target_calories) * 100, 0) /
          weeksWithData.length;
        const avgProteinAdherence =
          weeksWithData.reduce((sum, w) => sum + (w.total_protein! / w.target_protein) * 100, 0) /
          weeksWithData.length;

        text += `Average calorie adherence: ${avgCalAdherence.toFixed(1)}%\n`;
        text += `Average protein adherence: ${avgProteinAdherence.toFixed(1)}%\n`;
      }

      // Effectiveness assessment
      text += `\nEffectiveness: `;
      if (phase === 'cut' && avgWeightChange < -0.5) {
        text += `✓ Effective cut (losing weight)\n`;
      } else if (phase === 'bulk' && avgWeightChange > 0.5) {
        text += `✓ Effective bulk (gaining weight)\n`;
      } else if (phase === 'maintenance' && Math.abs(avgWeightChange) < 0.5) {
        text += `✓ Effective maintenance (stable weight)\n`;
      } else {
        text += `⚠ Phase goals not met\n`;
      }
    } else {
      text += `Insufficient data for analysis\n`;
    }

    text += `\n`;
  });

  // Overall recommendations
  const recentWeeks = weeks.slice(-4); // Last 4 weeks
  if (recentWeeks.length >= 2) {
    const validRecent = recentWeeks.filter(
      (w) => w.average_weight != null && w.week_over_week_weight_change != null
    );
    if (validRecent.length >= 2) {
      const avgWeeklyChange =
        validRecent.reduce((sum, w) => sum + (w.week_over_week_weight_change || 0), 0) / validRecent.length;

      // Assume 200 cal daily surplus for suggestion (placeholder)
      const suggestion = suggestPhase(200, avgWeeklyChange);

      text += `RECOMMENDATION:\n`;
      text += `Based on recent trends, suggested phase: ${suggestion.suggestedPhase.toUpperCase()}\n`;
      text += `Reasoning: ${suggestion.reasoning}\n`;
      text += `Confidence: ${(suggestion.confidence * 100).toFixed(0)}%\n`;
    }
  }

  return {
    content: [
      {
        type: 'text',
        text,
      },
    ],
  };
}
