/**
 * MCP Tool: Get weight trend
 */

import { D1Database } from '@cloudflare/workers-types';
import { getWeightReadings } from '../db/queries';

export const weightTrendTool = {
  name: 'get_weight_trend',
  description: 'Get all weight readings in a date range for trend analysis',
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

export async function executeWeightTrend(db: D1Database, args: { startDate: string; endDate: string }) {
  const readings = await getWeightReadings(db, args.startDate, args.endDate);

  if (readings.length === 0) {
    return {
      content: [
        {
          type: 'text',
          text: `No weight readings found between ${args.startDate} and ${args.endDate}`,
        },
      ],
    };
  }

  // Calculate statistics
  const weights = readings.map((r) => r.weight);
  const avgWeight = weights.reduce((a, b) => a + b, 0) / weights.length;
  const minWeight = Math.min(...weights);
  const maxWeight = Math.max(...weights);
  const totalChange = weights[weights.length - 1] - weights[0];

  // Format response
  let text = `Weight Trend Analysis (${args.startDate} to ${args.endDate})\n\n`;
  text += `SUMMARY:\n`;
  text += `- Total readings: ${readings.length}\n`;
  text += `- Average weight: ${avgWeight.toFixed(1)} lbs\n`;
  text += `- Min weight: ${minWeight.toFixed(1)} lbs\n`;
  text += `- Max weight: ${maxWeight.toFixed(1)} lbs\n`;
  text += `- Total change: ${totalChange >= 0 ? '+' : ''}${totalChange.toFixed(1)} lbs\n\n`;

  text += `READINGS:\n`;
  readings.forEach((r) => {
    text += `${r.date}: ${r.weight.toFixed(1)} lbs`;
    if (r.body_fat_percentage) {
      text += ` | BF: ${r.body_fat_percentage.toFixed(1)}%`;
    }
    if (r.muscle_mass_percentage) {
      text += ` | MM: ${r.muscle_mass_percentage.toFixed(1)}%`;
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
