/**
 * Database query functions for D1
 */

import { D1Database } from '@cloudflare/workers-types';

export interface WeekRecord {
  id: string;
  start_date: string;
  end_date: string;
  target_calories: number;
  target_protein: number;
  target_steps: number;
  target_cardio: number;
  phase: string;
  total_steps?: number;
  total_calories?: number;
  total_protein?: number;
  total_cardio_calories?: number;
  average_weight?: number;
  week_over_week_weight_change?: number;
  body_fat_percentage?: number;
  body_fat_change?: number;
  muscle_mass_percentage?: number;
  muscle_mass_change?: number;
  is_complete: number;
  completed_at?: string;
  created_at: string;
  updated_at: string;
}

export interface WeightReading {
  id: string;
  date: string;
  weight: number;
  body_fat_percentage?: number;
  muscle_mass_percentage?: number;
  source: string;
  created_at: string;
}

export interface DailyMetrics {
  id: string;
  date: string;
  steps: number;
  calories: number;
  protein: number;
  cardio_calories: number;
  weight?: number;
  seven_day_average_weight?: number;
  created_at: string;
}

// MARK: - Week Operations

export async function getWeekByStartDate(db: D1Database, startDate: string): Promise<WeekRecord | null> {
  const result = await db
    .prepare('SELECT * FROM weeks WHERE start_date = ? LIMIT 1')
    .bind(startDate)
    .first<WeekRecord>();

  return result || null;
}

export async function getCurrentWeek(db: D1Database): Promise<WeekRecord | null> {
  const result = await db
    .prepare('SELECT * FROM current_week LIMIT 1')
    .first<WeekRecord>();

  return result || null;
}

export async function getWeeks(db: D1Database, limit: number, offset: number): Promise<WeekRecord[]> {
  const result = await db
    .prepare('SELECT * FROM completed_weeks LIMIT ? OFFSET ?')
    .bind(limit, offset)
    .all<WeekRecord>();

  return result.results || [];
}

export async function createWeek(db: D1Database, week: Partial<WeekRecord>): Promise<void> {
  const now = new Date().toISOString();

  await db
    .prepare(`
      INSERT INTO weeks (
        id, start_date, end_date,
        target_calories, target_protein, target_steps, target_cardio, phase,
        total_steps, total_calories, total_protein, total_cardio_calories,
        average_weight, week_over_week_weight_change,
        body_fat_percentage, body_fat_change,
        muscle_mass_percentage, muscle_mass_change,
        is_complete, completed_at, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `)
    .bind(
      week.id,
      week.start_date,
      week.end_date,
      week.target_calories || 0,
      week.target_protein || 0,
      week.target_steps || 0,
      week.target_cardio || 0,
      week.phase || 'maintenance',
      week.total_steps || null,
      week.total_calories || null,
      week.total_protein || null,
      week.total_cardio_calories || null,
      week.average_weight || null,
      week.week_over_week_weight_change || null,
      week.body_fat_percentage || null,
      week.body_fat_change || null,
      week.muscle_mass_percentage || null,
      week.muscle_mass_change || null,
      week.is_complete || 0,
      week.completed_at || null,
      now,
      now
    )
    .run();
}

export async function updateWeek(db: D1Database, id: string, updates: Partial<WeekRecord>): Promise<void> {
  const now = new Date().toISOString();

  // Build dynamic update query
  const fields: string[] = [];
  const values: any[] = [];

  Object.entries(updates).forEach(([key, value]) => {
    if (key !== 'id' && key !== 'created_at') {
      fields.push(`${key} = ?`);
      values.push(value);
    }
  });

  fields.push('updated_at = ?');
  values.push(now);
  values.push(id);

  const query = `UPDATE weeks SET ${fields.join(', ')} WHERE id = ?`;

  await db.prepare(query).bind(...values).run();
}

export async function updateWeekTargets(
  db: D1Database,
  id: string,
  targets: {
    target_calories: number;
    target_protein: number;
    target_steps: number;
    target_cardio: number;
    phase: string;
  }
): Promise<void> {
  const now = new Date().toISOString();

  await db
    .prepare(`
      UPDATE weeks
      SET target_calories = ?, target_protein = ?, target_steps = ?, target_cardio = ?, phase = ?, updated_at = ?
      WHERE id = ?
    `)
    .bind(
      targets.target_calories,
      targets.target_protein,
      targets.target_steps,
      targets.target_cardio,
      targets.phase,
      now,
      id
    )
    .run();
}

// MARK: - Weight Reading Operations

export async function createWeightReading(db: D1Database, reading: Partial<WeightReading>): Promise<void> {
  const now = new Date().toISOString();

  await db
    .prepare(`
      INSERT INTO weight_readings (id, date, weight, body_fat_percentage, muscle_mass_percentage, source, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `)
    .bind(
      reading.id,
      reading.date,
      reading.weight,
      reading.body_fat_percentage || null,
      reading.muscle_mass_percentage || null,
      reading.source || 'API',
      now
    )
    .run();
}

export async function getWeightReadings(
  db: D1Database,
  startDate: string,
  endDate: string
): Promise<WeightReading[]> {
  const result = await db
    .prepare('SELECT * FROM weight_readings WHERE date >= ? AND date <= ? ORDER BY date ASC')
    .bind(startDate, endDate)
    .all<WeightReading>();

  return result.results || [];
}

export async function calculateRollingAverage(
  db: D1Database,
  targetDate: string,
  windowDays: number = 7
): Promise<{ average: number | null; confidence: number; readingCount: number }> {
  // Calculate date range for the window
  const date = new Date(targetDate);
  const windowStart = new Date(date);
  windowStart.setDate(windowStart.getDate() - windowDays + 1);

  const readings = await getWeightReadings(db, windowStart.toISOString(), targetDate);

  if (readings.length < 3) {
    return {
      average: null,
      confidence: 0,
      readingCount: readings.length,
    };
  }

  const sum = readings.reduce((acc, r) => acc + r.weight, 0);
  const average = sum / readings.length;
  const confidence = readings.length / windowDays;

  return {
    average,
    confidence,
    readingCount: readings.length,
  };
}

// MARK: - Daily Metrics Operations

export async function createDailyMetrics(db: D1Database, metrics: Partial<DailyMetrics>): Promise<void> {
  const now = new Date().toISOString();

  await db
    .prepare(`
      INSERT OR REPLACE INTO daily_metrics (id, date, steps, calories, protein, cardio_calories, weight, seven_day_average_weight, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `)
    .bind(
      metrics.id,
      metrics.date,
      metrics.steps || 0,
      metrics.calories || 0,
      metrics.protein || 0,
      metrics.cardio_calories || 0,
      metrics.weight || null,
      metrics.seven_day_average_weight || null,
      now
    )
    .run();
}

export async function getDailyMetrics(db: D1Database, startDate: string, endDate: string): Promise<DailyMetrics[]> {
  const result = await db
    .prepare('SELECT * FROM daily_metrics WHERE date >= ? AND date <= ? ORDER BY date ASC')
    .bind(startDate, endDate)
    .all<DailyMetrics>();

  return result.results || [];
}
