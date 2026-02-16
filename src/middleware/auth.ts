import { Request, Response, NextFunction } from 'express';
import logger from '../utils/logger.js';
import { randomUUID } from 'crypto';

/**
 * Middleware to handle session-based identity.
 * Automatically generates a new session ID for new users.
 * Persists session ID via X-Session-Id header.
 */
export const sessionHandler = (req: Request, res: Response, next: NextFunction) => {
  let sessionId = req.cookies?.mcp_sid || (req.headers['x-session-id'] as string);
  if (!sessionId) {
    sessionId = randomUUID();
    // Set cookie: valid for 30 days, readable by client (since user said "persisted on client"), 
    // but browser will handle it automatically.
    res.cookie('mcp_sid', sessionId, { 
      maxAge: 30 * 24 * 60 * 60 * 1000, 
      httpOnly: false, // Set to false so user's expectation of "persisted on client" (possibly via JS) is met, though browser does it.
      path: '/' 
    });
    logger.info(`Generated new session ID cookie: ${sessionId} for ${req.method} ${req.path}`);
  } else {
    logger.debug(`Existing session ID cookie found: ${sessionId} for ${req.method} ${req.path}`);
  }
  
  // Attach sessionId to request for use in handlers
  (req as any).sessionId = sessionId;

  next();
};

/**
 * Legacy authenticate middleware - kept for backward compatibility if needed,
 * but now it just delegates to sessionHandler or acts as a pass-through
 * as per the requirement to "do not use API Authentication for protect api".
 */
export const authenticate = sessionHandler;
