// Auth Middleware - JWT Token Verification
// Verifies JWT tokens and attaches user info to req.user

const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');

// JWT secret from environment variable
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

/**
 * Middleware to authenticate JWT tokens
 * Verifies the token and attaches decoded user info to req.user
 */
function authenticateToken(req, res, next) {
  try {
    // Get token from Authorization header
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer <token>

    if (!token) {
      logger.warn('[Auth] No token provided');
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Authentication token is required'
      });
    }

    // Verify token
    jwt.verify(token, JWT_SECRET, (err, decoded) => {
      if (err) {
        logger.warn('[Auth] Invalid token:', err.message);
        return res.status(401).json({
          error: 'Unauthorized',
          message: 'Invalid or expired token'
        });
      }

      // Attach user info to request
      req.user = {
        username: decoded.username,
        displayName: decoded.displayName,
        email: decoded.email,
        role: decoded.role,
        groups: decoded.groups || [],
        permissions: decoded.permissions || {},
        authMethod: decoded.authMethod
      };

      logger.info(`[Auth] Authenticated: ${req.user.username} (${req.user.groups.join(', ')})`);
      next();
    });
  } catch (error) {
    logger.error('[Auth] Error in authentication middleware:', error);
    return res.status(500).json({
      error: 'Internal Server Error',
      message: 'Authentication failed'
    });
  }
}

/**
 * Optional authentication - attaches user if token is valid, but doesn't require it
 */
function optionalAuth(req, res, next) {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return next(); // No token, continue without user
    }

    jwt.verify(token, JWT_SECRET, (err, decoded) => {
      if (!err) {
        req.user = {
          username: decoded.username,
          displayName: decoded.displayName,
          email: decoded.email,
          role: decoded.role,
          groups: decoded.groups || [],
          permissions: decoded.permissions || {},
          authMethod: decoded.authMethod
        };
        logger.info(`[Auth] Optional auth: ${req.user.username}`);
      }
      next();
    });
  } catch (error) {
    logger.error('[Auth] Error in optional auth middleware:', error);
    next();
  }
}

module.exports = {
  authenticateToken,
  optionalAuth
};
