# Health Tracker - Deployment Guide

Complete guide to deploying the Health Tracker app (iOS + MCP Server).

## Table of Contents

1. [MCP Server Deployment](#mcp-server-deployment)
2. [iOS App Setup](#ios-app-setup)
3. [Testing the Integration](#testing-the-integration)
4. [Troubleshooting](#troubleshooting)

---

## MCP Server Deployment

### Prerequisites

- Cloudflare account (free tier): https://dash.cloudflare.com/sign-up
- Node.js 18+ installed
- Wrangler CLI installed: `npm install -g wrangler`

### Step 1: Authenticate with Cloudflare

```bash
# Login to Cloudflare
wrangler login

# This will open a browser for authentication
```

### Step 2: Install Dependencies

```bash
cd mcp-server
npm install
```

### Step 3: Create D1 Database

```bash
# Create the database
wrangler d1 create health-tracker-db
```

**Output will look like:**

```
✅ Successfully created DB 'health-tracker-db'

[[d1_databases]]
binding = "DB"
database_name = "health-tracker-db"
database_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

**Copy the `database_id` and update `wrangler.toml`:**

```toml
[[d1_databases]]
binding = "DB"
database_name = "health-tracker-db"
database_id = "YOUR_DATABASE_ID_HERE"  # Paste your ID here
```

### Step 4: Run Database Migrations

```bash
# Test locally first
wrangler d1 execute health-tracker-db --local --file=./src/db/schema.sql

# Verify it worked
wrangler d1 execute health-tracker-db --local --command="SELECT name FROM sqlite_master WHERE type='table'"
```

### Step 5: Generate and Set API Key

```bash
# Generate a secure API key (32 bytes, base64 encoded)
openssl rand -base64 32

# Example output: "dGhpc2lzYXJhbmRvbWtleWZvcnlvdXJhcHBsaWNhdGlvbg=="

# Set it as a Cloudflare secret
wrangler secret put API_KEY
# When prompted, paste the generated key
```

**Save this API key** - you'll need it for:

1. iOS app configuration
2. Claude MCP configuration

### Step 6: Deploy to Cloudflare

```bash
# Deploy the worker
npm run deploy
```

**Output will look like:**

```
✨ Success! Uploaded 1 file
Published health-tracker-mcp (0.42 sec)
  https://health-tracker-mcp.your-subdomain.workers.dev
```

**Save this URL** - this is your MCP server endpoint!

### Step 7: Run Remote Migrations

```bash
# Now create tables on the remote database
npm run db:migrate:remote
```

### Step 8: Test the Deployment

```bash
# Test health endpoint (no auth needed)
curl https://health-tracker-mcp.your-subdomain.workers.dev/api/health

# Expected response:
# {"status":"ok","timestamp":"2024-..."}

# Test authenticated endpoint
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://health-tracker-mcp.your-subdomain.workers.dev/api/current-week

# Expected: null or week data (if you've created a week)
```

---

## iOS App Setup

### Prerequisites

- Xcode 15+ (for iOS 18 support)
- Apple Developer account (free tier for personal use)
- Physical iPhone or Simulator

### Step 1: Create Xcode Project

1. Open Xcode
2. Create new iOS App project
   - **Product Name**: HealthTracker
   - **Organization Identifier**: com.yourname
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Include Tests**: Yes

### Step 2: Add Source Files

Copy all files from `ios-app/HealthTracker/` into your Xcode project:

```
HealthTracker/
├── Models/
│   ├── Phase.swift
│   ├── WeekRecord.swift
│   ├── WeightReading.swift
│   └── DailyMetrics.swift
├── Services/
│   ├── HealthKitManager.swift
│   ├── APIService.swift
│   ├── CacheManager.swift
│   └── KeychainManager.swift
└── Utils/
    ├── DateHelpers.swift
    ├── WeightAverageCalculator.swift
    ├── PhaseDetector.swift
    └── CalorieBalanceCalculator.swift
```

**Note**: Views are not yet created in this initial setup - you'll need to build them or they'll be in a future implementation.

### Step 3: Configure HealthKit Capabilities

1. In Xcode, select your project
2. Select the HealthTracker target
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "HealthKit"

### Step 4: Add Info.plist Entries

Add these keys to `Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Health Tracker needs access to read your health data including steps, calories, protein, weight, body fat percentage, and muscle mass to provide weekly summaries and trend analysis.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Health Tracker does not write health data, only reads it.</string>
```

### Step 5: Configure API Endpoint

On first launch, the app will prompt for:

1. **Server URL**: `https://health-tracker-mcp.your-subdomain.workers.dev`
2. **API Key**: The key you generated earlier

These are stored securely in the iOS Keychain.

---

## Claude MCP Configuration

### Step 1: Locate Claude Config File

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`

**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

### Step 2: Add MCP Server

Create or edit the file with:

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

**Replace**:

- `your-subdomain` with your actual Cloudflare Workers subdomain
- `YOUR_API_KEY_HERE` with your API key

### Step 3: Restart Claude Desktop

Close and reopen Claude Desktop for the changes to take effect.

### Step 4: Test MCP Integration

In Claude, try asking:

```
"What tools do you have available from the health-tracker server?"

"Get my current week status"
```

Claude should be able to access your health data via MCP tools!

---

## Testing the Integration

### 1. Test MCP Server Directly

```bash
# Create a test week
curl -X POST https://your-server.workers.dev/api/weeks \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-week-1",
    "start_date": "2024-10-20",
    "end_date": "2024-10-26",
    "target_calories": 14000,
    "target_protein": 1000,
    "target_steps": 70000,
    "target_cardio": 2000,
    "phase": "cut",
    "is_complete": 0
  }'

# Verify it was created
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://your-server.workers.dev/api/current-week
```

### 2. Test MCP Tools via Claude

Ask Claude:

```
"Get my current week summary"

"Show me my weight trend from 2024-10-01 to 2024-10-31"

"What's my weekly history for the last 4 weeks?"
```

### 3. Test iOS App Integration

1. Launch the app
2. Enter your server URL and API key
3. Grant HealthKit permissions
4. Check that data syncs from HealthKit
5. Verify data appears in the app
6. Confirm data is saved to MCP server

---

## Troubleshooting

### MCP Server Issues

#### "Database not found" error

```bash
# Run migrations
wrangler d1 execute health-tracker-db --remote --file=./src/db/schema.sql
```

#### "Invalid API key" error

```bash
# Reset the API key
wrangler secret put API_KEY

# Make sure to update it in:
# 1. iOS app settings
# 2. Claude MCP config
```

#### Server not responding

```bash
# Check deployment status
wrangler deployments list

# View logs
wrangler tail

# Redeploy
npm run deploy
```

### iOS App Issues

#### HealthKit permission denied

1. Go to iPhone Settings → Privacy → Health → HealthTracker
2. Enable all required permissions
3. Restart the app

#### API connection failed

1. Check server URL is correct (include `https://`)
2. Verify API key matches the one set on the server
3. Test the endpoint with curl to confirm it's working
4. Check internet connection

#### Data not syncing

1. Check that source apps (MyFitnessPal, Withings) are syncing to Apple Health
2. Verify HealthKit permissions are granted
3. Pull to refresh in the app
4. Check app logs for errors

### Claude MCP Issues

#### Claude can't see the tools

1. Verify `claude_desktop_config.json` is in the correct location
2. Check JSON syntax is valid (use a JSON validator)
3. Restart Claude Desktop
4. Check the server URL ends with `/mcp`

#### "Authentication failed" in Claude

1. Verify the API key in the config matches the server
2. Check there are no extra spaces or quotes
3. Ensure the Authorization header format is exact: `Bearer YOUR_KEY`

---

## Production Checklist

Before going live:

- [ ] MCP server deployed to Cloudflare
- [ ] Database created and migrated
- [ ] API key set as Cloudflare secret
- [ ] Server endpoint tested with curl
- [ ] iOS app configured with server URL and API key
- [ ] HealthKit permissions granted
- [ ] Test data syncing from app to server
- [ ] Claude MCP configuration added
- [ ] Claude can successfully query health data
- [ ] All MCP tools tested via Claude
- [ ] Backup API key saved securely (e.g., password manager)

---

## Next Steps

1. **Build iOS UI Views** - Dashboard, history, trends, check-in
2. **Add Error Handling** - Offline mode, retry logic, user feedback
3. **Implement Auto-sync** - Background refresh (requires Apple Developer Program)
4. **Add Notifications** - Sunday check-in reminders
5. **Create iOS Widgets** - Home screen/lock screen widgets
6. **Build Web Dashboard** (optional) - View data in browser

---

## Support

For issues:

1. Check logs: `wrangler tail`
2. Review Cloudflare dashboard: https://dash.cloudflare.com
3. Test API endpoints with curl
4. Verify HealthKit permissions in iOS Settings

## Security Notes

- **Never commit your API key to git**
- Store API key in Cloudflare secrets only
- Use iOS Keychain for local storage in the app
- Rotate API key periodically for security
- Use HTTPS for all connections (enforced by Cloudflare)
