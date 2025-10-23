/**
 * HTTP API routes for iOS app
 */

import { Hono } from 'hono';
import { Env } from '../auth';
import * as db from '../db/queries';

const api = new Hono<{ Bindings: Env }>();

// Health check endpoint (no auth required)
api.get('/health', (c) => {
  return c.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// MARK: - Week Operations

// Get current week
api.get('/current-week', async (c) => {
  const week = await db.getCurrentWeek(c.env.DB);
  return c.json(week);
});

// Get specific week by start date
api.get('/weeks/:startDate', async (c) => {
  const startDate = c.req.param('startDate');
  const week = await db.getWeekByStartDate(c.env.DB, startDate);

  if (!week) {
    return c.json({ error: 'Week not found' }, 404);
  }

  return c.json(week);
});

// Get list of weeks
api.get('/weeks', async (c) => {
  const limit = parseInt(c.req.query('limit') || '6');
  const offset = parseInt(c.req.query('offset') || '0');

  const weeks = await db.getWeeks(c.env.DB, limit, offset);
  return c.json(weeks);
});

// Create or update week
api.post('/weeks', async (c) => {
  const body = await c.req.json();

  // Check if week exists
  const existing = await db.getWeekByStartDate(c.env.DB, body.start_date);

  if (existing) {
    // Update existing week
    await db.updateWeek(c.env.DB, existing.id, body);
    return c.json({ message: 'Week updated', id: existing.id });
  } else {
    // Create new week
    const id = body.id || crypto.randomUUID();
    await db.createWeek(c.env.DB, { ...body, id });
    return c.json({ message: 'Week created', id }, 201);
  }
});

// Update week targets
api.put('/weeks/:id/targets', async (c) => {
  const id = c.req.param('id');
  const body = await c.req.json();

  await db.updateWeekTargets(c.env.DB, id, body);
  return c.json({ message: 'Targets updated' });
});

// MARK: - Weight Operations

// Create weight reading
api.post('/weight', async (c) => {
  const body = await c.req.json();
  const id = body.id || crypto.randomUUID();

  await db.createWeightReading(c.env.DB, { ...body, id });
  return c.json({ message: 'Weight reading saved', id }, 201);
});

// Get weight readings
api.get('/weight', async (c) => {
  const start = c.req.query('start');
  const end = c.req.query('end');

  if (!start || !end) {
    return c.json({ error: 'Missing start or end date' }, 400);
  }

  const readings = await db.getWeightReadings(c.env.DB, start, end);
  return c.json(readings);
});

// Get rolling average
api.get('/weight/average', async (c) => {
  const date = c.req.query('date');
  const window = parseInt(c.req.query('window') || '7');

  if (!date) {
    return c.json({ error: 'Missing date parameter' }, 400);
  }

  const result = await db.calculateRollingAverage(c.env.DB, date, window);
  return c.json(result);
});

// MARK: - Daily Metrics Operations

// Create daily metrics
api.post('/daily-metrics', async (c) => {
  const body = await c.req.json();
  const id = body.id || crypto.randomUUID();

  await db.createDailyMetrics(c.env.DB, { ...body, id });
  return c.json({ message: 'Daily metrics saved', id }, 201);
});

// Get daily metrics
api.get('/daily-metrics', async (c) => {
  const start = c.req.query('start');
  const end = c.req.query('end');

  if (!start || !end) {
    return c.json({ error: 'Missing start or end date' }, 400);
  }

  const metrics = await db.getDailyMetrics(c.env.DB, start, end);
  return c.json(metrics);
});

// Get body composition data
api.get('/body-composition', async (c) => {
  const start = c.req.query('start');
  const end = c.req.query('end');

  if (!start || !end) {
    return c.json({ error: 'Missing start or end date' }, 400);
  }

  const readings = await db.getWeightReadings(c.env.DB, start, end);

  // Filter to readings with body composition data
  const compData = readings
    .filter((r) => r.body_fat_percentage != null || r.muscle_mass_percentage != null)
    .map((r) => ({
      date: r.date,
      bodyFatPercentage: r.body_fat_percentage,
      muscleMassPercentage: r.muscle_mass_percentage,
      weight: r.weight,
    }));

  return c.json(compData);
});

export default api;
