/**
 * MCP Tool: Get week summary
 */

import { D1Database } from '@cloudflare/workers-types';
import { getWeekByStartDate } from '../db/queries';

export const weekSummaryTool = {
  name: 'get_week_summary',
  description: 'Get complete week data including targets, actuals, and body composition for a specific week',
  inputSchema: {
    type: 'object',
    properties: {
      startDate: {
        type: 'string',
        description: 'The start date of the week in ISO format (YYYY-MM-DD)',
      },
    },
    required: ['startDate'],
  },
};

export async function executeWeekSummary(db: D1Database, args: { startDate: string }) {
  const week = await getWeekByStartDate(db, args.startDate);

  if (!week) {
    return {
      content: [
        {
          type: 'text',
          text: `No week found starting on ${args.startDate}`,
        },
      ],
    };
  }

  // Format the response
  const summary = `
Week Summary: ${args.startDate}
Phase: ${week.phase}

TARGETS:
- Calories: ${week.target_calories} kcal
- Protein: ${week.target_protein}g
- Steps: ${week.target_steps.toLocaleString()}
- Cardio: ${week.target_cardio} kcal

ACTUALS:
- Calories: ${week.total_calories || 'N/A'} kcal ${week.total_calories ? `(${((week.total_calories / week.target_calories) * 100).toFixed(1)}%)` : ''}
- Protein: ${week.total_protein || 'N/A'}g ${week.total_protein ? `(${((week.total_protein / week.target_protein) * 100).toFixed(1)}%)` : ''}
- Steps: ${week.total_steps?.toLocaleString() || 'N/A'} ${week.total_steps ? `(${((week.total_steps / week.target_steps) * 100).toFixed(1)}%)` : ''}
- Cardio: ${week.total_cardio_calories || 'N/A'} kcal ${week.total_cardio_calories ? `(${((week.total_cardio_calories / week.target_cardio) * 100).toFixed(1)}%)` : ''}

BODY COMPOSITION:
- Average Weight: ${week.average_weight ? `${week.average_weight.toFixed(1)} lbs` : 'N/A'}
- Week-over-Week Change: ${week.week_over_week_weight_change ? `${week.week_over_week_weight_change >= 0 ? '+' : ''}${week.week_over_week_weight_change.toFixed(1)} lbs` : 'N/A'}
- Body Fat: ${week.body_fat_percentage ? `${week.body_fat_percentage.toFixed(1)}%` : 'N/A'}${week.body_fat_change ? ` (${week.body_fat_change >= 0 ? '+' : ''}${week.body_fat_change.toFixed(1)}%)` : ''}
- Muscle Mass: ${week.muscle_mass_percentage ? `${week.muscle_mass_percentage.toFixed(1)}%` : 'N/A'}${week.muscle_mass_change ? ` (${week.muscle_mass_change >= 0 ? '+' : ''}${week.muscle_mass_change.toFixed(1)}%)` : ''}

Status: ${week.is_complete ? `Completed on ${week.completed_at}` : 'In Progress'}
`.trim();

  return {
    content: [
      {
        type: 'text',
        text: summary,
      },
    ],
  };
}
