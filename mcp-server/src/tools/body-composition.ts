/**
 * MCP Tool: Get body composition trend
 */

import { D1Database } from '@cloudflare/workers-types';
import { getWeightReadings } from '../db/queries';

export const bodyCompositionTool = {
  name: 'get_body_composition',
  description: 'Get body fat % and muscle mass % trends over time',
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

export async function executeBodyComposition(db: D1Database, args: { startDate: string; endDate: string }) {
  const readings = await getWeightReadings(db, args.startDate, args.endDate);

  // Filter to readings with body composition data
  const compReadings = readings.filter((r) => r.body_fat_percentage != null || r.muscle_mass_percentage != null);

  if (compReadings.length === 0) {
    return {
      content: [
        {
          type: 'text',
          text: `No body composition data found between ${args.startDate} and ${args.endDate}`,
        },
      ],
    };
  }

  // Calculate statistics
  const bfReadings = compReadings.filter((r) => r.body_fat_percentage != null);
  const mmReadings = compReadings.filter((r) => r.muscle_mass_percentage != null);

  let text = `Body Composition Trend (${args.startDate} to ${args.endDate})\n\n`;

  if (bfReadings.length > 0) {
    const bodyFats = bfReadings.map((r) => r.body_fat_percentage!);
    const avgBF = bodyFats.reduce((a, b) => a + b, 0) / bodyFats.length;
    const minBF = Math.min(...bodyFats);
    const maxBF = Math.max(...bodyFats);
    const bfChange = bodyFats[bodyFats.length - 1] - bodyFats[0];

    text += `BODY FAT PERCENTAGE:\n`;
    text += `- Readings: ${bfReadings.length}\n`;
    text += `- Average: ${avgBF.toFixed(1)}%\n`;
    text += `- Range: ${minBF.toFixed(1)}% - ${maxBF.toFixed(1)}%\n`;
    text += `- Change: ${bfChange >= 0 ? '+' : ''}${bfChange.toFixed(1)}%\n\n`;
  }

  if (mmReadings.length > 0) {
    const muscleMasses = mmReadings.map((r) => r.muscle_mass_percentage!);
    const avgMM = muscleMasses.reduce((a, b) => a + b, 0) / muscleMasses.length;
    const minMM = Math.min(...muscleMasses);
    const maxMM = Math.max(...muscleMasses);
    const mmChange = muscleMasses[muscleMasses.length - 1] - muscleMasses[0];

    text += `MUSCLE MASS PERCENTAGE:\n`;
    text += `- Readings: ${mmReadings.length}\n`;
    text += `- Average: ${avgMM.toFixed(1)}%\n`;
    text += `- Range: ${minMM.toFixed(1)}% - ${maxMM.toFixed(1)}%\n`;
    text += `- Change: ${mmChange >= 0 ? '+' : ''}${mmChange.toFixed(1)}%\n\n`;
  }

  text += `DETAILED READINGS:\n`;
  compReadings.forEach((r) => {
    text += `${r.date}: `;
    if (r.body_fat_percentage) {
      text += `BF ${r.body_fat_percentage.toFixed(1)}%`;
    }
    if (r.muscle_mass_percentage) {
      if (r.body_fat_percentage) text += ' | ';
      text += `MM ${r.muscle_mass_percentage.toFixed(1)}%`;
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
