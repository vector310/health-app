-- Health Tracker MCP Server Database Schema
-- Cloudflare D1 (SQLite-based)

-- Weeks table: stores weekly records with targets and actuals
CREATE TABLE IF NOT EXISTS weeks (
    id TEXT PRIMARY KEY,
    start_date TEXT NOT NULL,
    end_date TEXT NOT NULL,

    -- Targets
    target_calories INTEGER,
    target_protein INTEGER,
    target_steps INTEGER,
    target_cardio INTEGER,
    phase TEXT,

    -- Actuals (aggregated)
    total_steps INTEGER,
    total_calories INTEGER,
    total_protein INTEGER,
    total_cardio_calories INTEGER,
    average_weight REAL,
    week_over_week_weight_change REAL,

    -- Body composition
    body_fat_percentage REAL,
    body_fat_change REAL,
    muscle_mass_percentage REAL,
    muscle_mass_change REAL,

    -- Metadata
    is_complete INTEGER DEFAULT 0,
    completed_at TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Weight readings table: individual weight and body composition measurements
CREATE TABLE IF NOT EXISTS weight_readings (
    id TEXT PRIMARY KEY,
    date TEXT NOT NULL,
    weight REAL NOT NULL,
    body_fat_percentage REAL,
    muscle_mass_percentage REAL,
    source TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Daily metrics table: granular daily data for trend analysis
CREATE TABLE IF NOT EXISTS daily_metrics (
    id TEXT PRIMARY KEY,
    date TEXT NOT NULL UNIQUE,
    steps INTEGER,
    calories INTEGER,
    protein INTEGER,
    cardio_calories INTEGER,
    weight REAL,
    seven_day_average_weight REAL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_weeks_start_date ON weeks(start_date);
CREATE INDEX IF NOT EXISTS idx_weeks_is_complete ON weeks(is_complete);
CREATE INDEX IF NOT EXISTS idx_weight_readings_date ON weight_readings(date);
CREATE INDEX IF NOT EXISTS idx_daily_metrics_date ON daily_metrics(date);

-- View for current week (in progress)
CREATE VIEW IF NOT EXISTS current_week AS
SELECT * FROM weeks
WHERE is_complete = 0
ORDER BY start_date DESC
LIMIT 1;

-- View for completed weeks
CREATE VIEW IF NOT EXISTS completed_weeks AS
SELECT * FROM weeks
WHERE is_complete = 1
ORDER BY start_date DESC;
