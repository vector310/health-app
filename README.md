# Health Tracker

A native iOS health tracking app with AI-powered analysis via Claude. Aggregates fitness and body composition data from Apple Health (synced from MyFitnessPal, Withings, etc.) to provide weekly summaries for PT check-ins and long-term trend analysis.

## Overview

This app solves the problem of manually tracking health metrics for personal trainer check-ins. Instead of copying data from multiple apps every week, Health Tracker:

- **Aggregates** data from Apple Health (steps, calories, protein, weight, body composition)
- **Calculates** weekly totals and rolling averages automatically
- **Provides** tap-to-copy metrics formatted for PT submissions
- **Tracks** long-term trends with beautiful charts
- **Enables** AI-powered conversational analysis via Claude

## Architecture

The app consists of two components:

### 1. iOS Native App (Swift/SwiftUI)

- Native iOS 18+ app with Liquid Glass design
- HealthKit integration for reading health data
- Local caching for offline access
- Tap-to-copy interface for weekly check-ins
- Trend visualization with interactive charts

### 2. Cloudflare MCP Server (TypeScript)

- Serverless backend on Cloudflare Workers (free tier)
- D1 SQLite database for data persistence
- MCP (Model Context Protocol) tools for Claude AI
- RESTful HTTP API for iOS app
- Global edge network for fast access

## Features

### Weekly Metrics Dashboard

Track current week's progress in real-time:

- Steps (from Apple Health)
- Calories & Protein (from MyFitnessPal → Apple Health)
- Cardio calories (from workouts)
- 7-day rolling average weight (from Withings → Apple Health)
- Body composition changes (body fat %, muscle mass %)

### Weekly Targets & Phases

- Set weekly targets for all metrics
- Tag each week as Cut/Maintenance/Bulk
- AI-suggested phases based on calorie balance and weight trends
- Phase alignment indicators

### Historical Analysis

- View last 6 weeks with infinite scroll
- Week-over-week comparisons
- Progress tracking against targets
- Phase effectiveness analysis

### Weight & Body Composition Trends

- Interactive charts with multiple time ranges (1-24 months)
- Toggle between weight, body fat %, muscle mass %
- Phase periods overlaid on charts
- 7-day rolling averages with confidence scoring

### PT Check-In Export

Sunday morning special interface:

- Tap-to-copy all required metrics
- Pre-formatted for quick submission
- Haptic feedback confirmation
- No navigation required

### AI-Powered Analysis

Ask Claude about your health data:

- "How's my weight trending over the last 3 months?"
- "Am I hitting my protein targets?"
- "What's my body composition change during this bulk?"
- "Which weeks had the best adherence?"

## Technology Stack

### iOS App

- **Language**: Swift
- **UI Framework**: SwiftUI (iOS 18+ Liquid Glass design)
- **Data**: HealthKit, Combine, URLSession
- **Storage**: UserDefaults (cache), Keychain (API credentials)

### MCP Server

- **Runtime**: Cloudflare Workers (serverless)
- **Language**: TypeScript
- **Framework**: Hono.js (lightweight web framework)
- **Database**: Cloudflare D1 (SQLite)
- **Protocol**: MCP for Claude integration
- **Auth**: Bearer token (API key)

## Project Structure

```
health-app/
├── ios-app/                    # iOS native app
│   └── HealthTracker/
│       ├── Models/             # Data models
│       ├── Services/           # HealthKit, API, Cache
│       ├── Utils/              # Calculations, helpers
│       ├── Views/              # SwiftUI views
│       └── ViewModels/         # View models
│
├── mcp-server/                 # Cloudflare MCP server
│   ├── src/
│   │   ├── index.ts           # Main entry point
│   │   ├── auth.ts            # Authentication
│   │   ├── api/               # HTTP API routes
│   │   ├── db/                # Database schema & queries
│   │   ├── tools/             # MCP tools for Claude
│   │   └── utils/             # Helpers & calculations
│   ├── package.json
│   └── wrangler.toml          # Cloudflare config
│
├── DEPLOYMENT.md               # Deployment guide
└── README.md                   # This file
```

## Quick Start

### Prerequisites

- **iOS Development**: Xcode 15+, iOS 18+ device/simulator
- **MCP Server**: Node.js 18+, Cloudflare account (free), Wrangler CLI
- **Health Data Sources**: MyFitnessPal app, Withings scale (or similar)

### 1. Deploy MCP Server

```bash
# Install dependencies
cd mcp-server
npm install

# Create Cloudflare D1 database
wrangler d1 create health-tracker-db

# Update wrangler.toml with database_id

# Run migrations
npm run db:migrate

# Generate and set API key
openssl rand -base64 32
wrangler secret put API_KEY

# Deploy to Cloudflare
npm run deploy
```

See [mcp-server/README.md](mcp-server/README.md) for detailed instructions.

### 2. Configure Claude MCP

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "health-tracker": {
      "url": "https://health-tracker-mcp.your-subdomain.workers.dev/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_API_KEY"
      }
    }
  }
}
```

Restart Claude Desktop.

### 3. Build iOS App

1. Open Xcode and create new iOS app project
2. Copy files from `ios-app/HealthTracker/` to your project
3. Add HealthKit capability
4. Add Info.plist entries for HealthKit permissions
5. Build and run on device/simulator
6. Enter your MCP server URL and API key
7. Grant HealthKit permissions

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete setup guide.

## Usage

### Daily Workflow

1. Live your life, track nutrition in MyFitnessPal, weigh yourself with Withings
2. Data automatically syncs to Apple Health
3. Open Health Tracker app to see current week progress
4. Data syncs to MCP server for backup and AI analysis

### Sunday Morning (PT Check-In)

1. Open Health Tracker app
2. View Sunday check-in interface (auto-shown before 10am)
3. Tap each metric to copy formatted value
4. Paste into your PT check-in form/message
5. Review week-over-week changes

### Monthly Review

1. Ask Claude: "Analyze my last 4 weeks of training"
2. Review trend charts in the app
3. Adjust targets for next phase
4. Update phase tag (cut/maintenance/bulk)

## Data Flow

```
MyFitnessPal → Apple Health ← Health Tracker App → MCP Server → Claude AI
Withings     ↗                                          ↓
                                                    D1 Database
```

1. **Source Apps** (MyFitnessPal, Withings) sync to Apple Health
2. **Health Tracker** reads from Apple Health via HealthKit
3. **App** calculates rolling averages, aggregates weekly totals
4. **MCP Server** stores data in Cloudflare D1 database
5. **Claude** analyzes your data via MCP tools

## Cost Breakdown

### Cloudflare (Free Tier)

- Workers: 100,000 requests/day
- D1 Database: 5GB storage, 5M reads/day, 100K writes/day
- Your usage: ~100 requests/day

**Cost: $0/month**

### Apple Developer Program

- NOT required for personal development/sideloading
- Only needed for App Store distribution

**Cost: $0** (or $99/year if publishing)

### Total: $0/month for personal use

## Security & Privacy

- ✅ All health data stored locally and in your private Cloudflare D1 database
- ✅ API key authentication for all server requests
- ✅ HTTPS enforced by Cloudflare
- ✅ API key stored in iOS Keychain (encrypted)
- ✅ No third-party analytics or tracking
- ✅ You own all your data
- ✅ Can delete everything anytime (Cloudflare dashboard)

## Future Enhancements (Post-V1)

- [ ] iOS widgets (home screen/lock screen)
- [ ] Push notifications for Sunday check-in reminder
- [ ] Background data sync (requires Apple Developer Program)
- [ ] Apple Watch companion app
- [ ] Photo progress tracking
- [ ] Nutrition breakdown (beyond protein)
- [ ] Exercise-specific tracking (sets/reps/weights)
- [ ] Web dashboard for viewing data in browser
- [ ] CSV export for detailed analysis
- [ ] Direct Google Form submission via API

## Contributing

This is a personal project, but feel free to fork and adapt for your own use!

## License

MIT

## Acknowledgments

- Built with Claude Code
- Inspired by the need to streamline weekly PT check-ins
- Uses Apple HealthKit, Cloudflare Workers, and the Model Context Protocol (MCP)