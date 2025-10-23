/**
 * Authentication middleware for API key validation
 */

import { Context } from 'hono';

export interface Env {
  API_KEY: string;
  DB: D1Database;
}

/**
 * Middleware to validate API key from Authorization header
 */
export async function authMiddleware(c: Context<{ Bindings: Env }>, next: () => Promise<void>) {
  const authHeader = c.req.header('Authorization');

  if (!authHeader) {
    return c.json({ error: 'Missing Authorization header' }, 401);
  }

  const [scheme, token] = authHeader.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return c.json({ error: 'Invalid Authorization header format. Use: Bearer <token>' }, 401);
  }

  const apiKey = c.env.API_KEY;

  if (!apiKey) {
    return c.json({ error: 'Server configuration error: API_KEY not set' }, 500);
  }

  if (token !== apiKey) {
    return c.json({ error: 'Invalid API key' }, 403);
  }

  await next();
}

/**
 * Check if request has valid API key (for use in route handlers)
 */
export function isAuthenticated(c: Context<{ Bindings: Env }>): boolean {
  const authHeader = c.req.header('Authorization');

  if (!authHeader) {
    return false;
  }

  const [scheme, token] = authHeader.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return false;
  }

  return token === c.env.API_KEY;
}
