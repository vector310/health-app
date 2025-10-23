/**
 * Health Tracker MCP Server
 * Cloudflare Worker with MCP tools for Claude AI analysis and HTTP API for iOS app
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { Env, authMiddleware } from './auth';
import apiRoutes from './api/routes';

// Import MCP tools
import { weekSummaryTool, executeWeekSummary } from './tools/week-summary';
import { weightTrendTool, executeWeightTrend } from './tools/weight-trend';
import { weeklyHistoryTool, executeWeeklyHistory } from './tools/weekly-history';
import { phaseAnalysisTool, executePhaseAnalysis } from './tools/phase-analysis';
import { bodyCompositionTool, executeBodyComposition } from './tools/body-composition';
import { currentWeekTool, executeCurrentWeek } from './tools/current-week';

const app = new Hono<{ Bindings: Env }>();

// CORS for iOS app
app.use('/*', cors());

// Health check (no auth)
app.get('/', (c) => {
  return c.json({
    name: 'Health Tracker MCP Server',
    version: '1.0.0',
    description: 'Personal health tracking with AI-powered analysis',
    endpoints: {
      api: '/api/*',
      mcp: '/mcp',
    },
  });
});

// HTTP API routes (with auth)
app.route('/api', apiRoutes);
app.use('/api/*', authMiddleware);

// MCP endpoint for Claude
app.post('/mcp', authMiddleware, async (c) => {
  const body = await c.req.json();

  // Handle MCP protocol
  if (body.method === 'tools/list') {
    // Return list of available MCP tools
    return c.json({
      tools: [
        weekSummaryTool,
        weightTrendTool,
        weeklyHistoryTool,
        phaseAnalysisTool,
        bodyCompositionTool,
        currentWeekTool,
      ],
    });
  }

  if (body.method === 'tools/call') {
    const toolName = body.params?.name;
    const args = body.params?.arguments || {};

    try {
      let result;

      switch (toolName) {
        case 'get_week_summary':
          result = await executeWeekSummary(c.env.DB, args);
          break;

        case 'get_weight_trend':
          result = await executeWeightTrend(c.env.DB, args);
          break;

        case 'get_weekly_history':
          result = await executeWeeklyHistory(c.env.DB, args);
          break;

        case 'analyze_phases':
          result = await executePhaseAnalysis(c.env.DB, args);
          break;

        case 'get_body_composition':
          result = await executeBodyComposition(c.env.DB, args);
          break;

        case 'get_current_week':
          result = await executeCurrentWeek(c.env.DB);
          break;

        default:
          return c.json({ error: `Unknown tool: ${toolName}` }, 400);
      }

      return c.json(result);
    } catch (error) {
      console.error('Tool execution error:', error);
      return c.json(
        {
          error: 'Tool execution failed',
          details: error instanceof Error ? error.message : String(error),
        },
        500
      );
    }
  }

  return c.json({ error: 'Unsupported MCP method' }, 400);
});

// Error handling
app.onError((err, c) => {
  console.error('Server error:', err);
  return c.json(
    {
      error: 'Internal server error',
      message: err.message,
    },
    500
  );
});

// 404 handler
app.notFound((c) => {
  return c.json({ error: 'Not found' }, 404);
});

export default app;
