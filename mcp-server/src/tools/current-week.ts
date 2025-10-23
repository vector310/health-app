/**
 * MCP Tool: Get current week status
 */

import { D1Database } from '@cloudflare/workers-types';
import { getCurrentWeek } from '../db/queries';

export const currentWeekTool = {
  name: 'get_current_week',
  description: 'Get the current in-progress week with running totals',
  inputSchema: {
    type: 'object',
    properties: {},
  },
};

export async function executeCurrentWeek(db: D1Database) {
  const week = await getCurrentWeek(db);

  if (!week) {
    return {
      content: [
        {
          type: 'text',
          text: 'No current week in progress. Start a new week to track metrics.',
        },
      ],
    };
  }

  const daysIntoWeek = Math.floor((Date.now() - new Date(week.start_date).getTime()) / (1000 * 60 * 60 * 24)) + 1;

  let text = `Current Week (Day ${daysIntoWeek} of 7)\n`;
  text += `${week.start_date} - ${week.end_date}\n`;
  text += `Phase: ${week.phase}\n\n`;

  text += `PROGRESS:\n`;
  text += `Steps: ${week.total_steps?.toLocaleString() || '0'} / ${week.target_steps.toLocaleString()} (${week.total_steps ? ((week.total_steps / week.target_steps) * 100).toFixed(1) : '0'}%)\n`;
  text += `Calories: ${week.total_calories || '0'} / ${week.target_calories} (${week.total_calories ? ((week.total_calories / week.target_calories) * 100).toFixed(1) : '0'}%)\n`;
  text += `Protein: ${week.total_protein || '0'}g / ${week.target_protein}g (${week.total_protein ? ((week.total_protein / week.target_protein) * 100).toFixed(1) : '0'}%)\n`;
  text += `Cardio: ${week.total_cardio_calories || '0'} / ${week.target_cardio} kcal (${week.total_cardio_calories ? ((week.total_cardio_calories / week.target_cardio) * 100).toFixed(1) : '0'}%)\n\n`;

  if (week.average_weight) {
    text += `CURRENT METRICS:\n`;
    text += `7-day avg weight: ${week.average_weight.toFixed(1)} lbs\n`;
    if (week.week_over_week_weight_change) {
      text += `Week-over-week: ${week.week_over_week_weight_change >= 0 ? '+' : ''}${week.week_over_week_weight_change.toFixed(1)} lbs\n`;
    }
    if (week.body_fat_percentage) {
      text += `Body fat: ${week.body_fat_percentage.toFixed(1)}%`;
      if (week.body_fat_change) {
        text += ` (${week.body_fat_change >= 0 ? '+' : ''}${week.body_fat_change.toFixed(1)}%)`;
      }
      text += `\n`;
    }
    if (week.muscle_mass_percentage) {
      text += `Muscle mass: ${week.muscle_mass_percentage.toFixed(1)}%`;
      if (week.muscle_mass_change) {
        text += ` (${week.muscle_mass_change >= 0 ? '+' : ''}${week.muscle_mass_change.toFixed(1)}%)`;
      }
      text += `\n`;
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
