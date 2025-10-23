# Health Tracker MCP Server

A Cloudflare Workers-based MCP (Model Context Protocol) server for personal health tracking with AI-powered analysis via Claude.

## Features

- **MCP Tools for Claude AI**: Query your health data conversationally through Claude
- **HTTP REST API**: For iOS app integration
- **Cloudflare D1 Database**: Serverless SQLite storage
- **Zero Cost**: Runs on Cloudflare's free tier
- **Global Edge Network**: Fast access from anywhere

## Prerequisites

- Node.js 18+ and npm
- Cloudflare account (free tier is sufficient)
- Wrangler CLI: `npm install -g wrangler`

## Quick Start

### 1. Install Dependencies

```bash
cd mcp-server
npm install
```

### 2. Create Cloudflare D1 Database

```bash
# Create the database
wrangler d1 create health-tracker-db

# Copy the database_id from output and paste it into wrangler.toml
# Update the database_id field in wrangler.toml
```

### 3. Run Migrations

```bash
# Create tables (local)
wrangler d1 execute health-tracker-db --local --file=./src/db/schema.sql

# Create tables (remote - after first deployment)
npm run db:migrate:remote
```

### 4. Set API Key Secret

```bash
# Generate a secure API key (or use your own)
openssl rand -base64 32

# Set it as a secret
wrangler secret put API_KEY
# Paste your generated API key when prompted
```

### 5. Deploy to Cloudflare

```bash
npm run deploy
```

Your server will be deployed to: `https://health-tracker-mcp.<your-subdomain>.workers.dev`

## Development

### Local Development

```bash
# Run local dev server
npm run dev

# Server will be available at http://localhost:8787
```

### Testing the API

```bash
# Health check (no auth)
curl https://your-worker.workers.dev/api/health

# Get current week (with auth)
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://your-worker.workers.dev/api/current-week
```

## MCP Configuration for Claude

Add this to your Claude Desktop config file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "health-tracker": {
      "url": "https://health-tracker-mcp.your-subdomain.workers.dev/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_API_KEY_HERE"
      }
    }
  }
}
```

## Available MCP Tools

Claude can use these tools to analyze your health data:

1. **get_current_week** - Get current week's progress
2. **get_week_summary** - Get complete data for a specific week
3. **get_weekly_history** - Get list of completed weeks
4. **get_weight_trend** - Analyze weight trends over time
5. **analyze_phases** - Analyze training phase effectiveness
6. **get_body_composition** - Track body fat and muscle mass trends

## Example Claude Queries

```
"How's my weight trending over the last 12 weeks?"

"Am I hitting my protein targets consistently?"

"What's my average calorie deficit during cut weeks?"

"Compare my last bulk phase to my current one"

"What's my body composition change over 6 months?"
```

## API Endpoints

### Weeks

- `GET /api/current-week` - Get current in-progress week
- `GET /api/weeks/:startDate` - Get specific week
- `GET /api/weeks?limit=6&offset=0` - List completed weeks
- `POST /api/weeks` - Create/update week
- `PUT /api/weeks/:id/targets` - Update week targets

### Weight

- `POST /api/weight` - Save weight reading
- `GET /api/weight?start=X&end=Y` - Get weight readings
- `GET /api/weight/average?date=X&window=7` - Get rolling average

### Daily Metrics

- `POST /api/daily-metrics` - Save daily metrics
- `GET /api/daily-metrics?start=X&end=Y` - Get daily metrics

### Body Composition

- `GET /api/body-composition?start=X&end=Y` - Get body composition data

## Database Schema

See [src/db/schema.sql](src/db/schema.sql) for the complete schema.

### Tables

- **weeks** - Weekly records with targets and actuals
- **weight_readings** - Individual weight and body composition readings
- **daily_metrics** - Daily aggregated health metrics

## Security

- API key authentication required for all endpoints (except `/api/health`)
- API key stored as Cloudflare secret (not in code)
- HTTPS enforced by Cloudflare
- CORS enabled for iOS app

## Costs

### Cloudflare Free Tier Limits

- **Workers**: 100,000 requests/day
- **D1 Database**: 5GB storage, 5M reads/day, 100K writes/day

**Estimated usage**: ~100 requests/day (well within free tier)

**Cost**: $0/month

## Troubleshooting

### Database not found

Make sure you've run the migrations:

```bash
wrangler d1 execute health-tracker-db --local --file=./src/db/schema.sql
```

### API key errors

Reset your API key:

```bash
wrangler secret put API_KEY
```

### MCP connection issues

1. Verify your API key is correct in Claude config
2. Check the server URL is correct
3. Test with curl to verify the server is responding

## Development Commands

```bash
# Install dependencies
npm install

# Run local dev server
npm run dev

# Deploy to Cloudflare
npm run deploy

# Create database
npm run db:create

# Run migrations (local)
npm run db:migrate

# Run migrations (remote)
npm run db:migrate:remote

# Type check
npm run type-check

# Run tests
npm test
```

## Project Structure

```
mcp-server/
├── src/
│   ├── index.ts              # Main entry point
│   ├── auth.ts               # Authentication middleware
│   ├── api/
│   │   └── routes.ts         # HTTP API routes
│   ├── db/
│   │   ├── schema.sql        # Database schema
│   │   └── queries.ts        # Database queries
│   ├── tools/                # MCP tools for Claude
│   │   ├── current-week.ts
│   │   ├── week-summary.ts
│   │   ├── weight-trend.ts
│   │   ├── weekly-history.ts
│   │   ├── phase-analysis.ts
│   │   └── body-composition.ts
│   └── utils/
│       ├── calculations.ts   # Health calculations
│       └── date-helpers.ts   # Date utilities
├── wrangler.toml             # Cloudflare config
├── package.json
└── tsconfig.json
```

## License

MIT
