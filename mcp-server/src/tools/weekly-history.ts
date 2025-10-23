/**
 * MCP Tool: Get weekly history
 */

import { D1Database } from '@cloudflare/workers-types';
import { getWeeks } from '../db/queries';

export const weeklyHistoryTool = {
  name: 'get_weekly_history',
  description: 'Get paginated list of completed weeks for historical analysis',
  inputSchema: {
    type: 'object',
    properties: {
      limit: {
        type: 'number',
        description: 'Number of weeks to return (default: 10)',
        default: 10,
      },
      offset: {
        type: 'number',
        description: 'Number of weeks to skip (default: 0)',
        default: 0,
      },
    },
  },
};

export async function executeWeeklyHistory(db: D1Database, args: { limit?: number; offset?: number }) {
  const limit = args.limit || 10;
  const offset = args.offset || 0;

  const weeks = await getWeeks(db, limit, offset);

  if (weeks.length === 0) {
    return {
      content: [
        {
          type: 'text',
          text: 'No completed weeks found',
        },
      ],
    };
  }

  let text = `Weekly History (showing ${weeks.length} weeks)\n\n`;

  weeks.forEach((week, index) => {
    text += `WEEK ${offset + index + 1}: ${week.start_date} (${week.phase})\n`;
    text += `Targets: ${week.target_calories} kcal | ${week.target_protein}g protein | ${week.target_steps.toLocaleString()} steps\n`;
    text += `Actuals: ${week.total_calories || 'N/A'} kcal | ${week.total_protein || 'N/A'}g protein | ${week.total_steps?.toLocaleString() || 'N/A'} steps\n`;
    text += `Weight: ${week.average_weight?.toFixed(1) || 'N/A'} lbs`;
    if (week.week_over_week_weight_change) {
      text += ` (${week.week_over_week_weight_change >= 0 ? '+' : ''}${week.week_over_week_weight_change.toFixed(1)} lbs)`;
    }
    text += `\n`;

    // Adherence calculation
    if (week.total_calories && week.total_protein && week.total_steps) {
      const calAdherence = (week.total_calories / week.target_calories) * 100;
      const proteinAdherence = (week.total_protein / week.target_protein) * 100;
      const stepsAdherence = (week.total_steps / week.target_steps) * 100;
      const avgAdherence = (calAdherence + proteinAdherence + stepsAdherence) / 3;
      text += `Adherence: ${avgAdherence.toFixed(1)}%\n`;
    }

    text += `\n`;
  });

  return {
    content: [
      {
        type: 'text',
        text,
      },
    ],
  };
}
