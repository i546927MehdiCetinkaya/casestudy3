const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const ldapService = require('../services/ldap');
const { getUserPermissions } = require('../middleware/rbac');
const logger = require('../utils/logger');

const router = express.Router();

// Fallback users for when LDAP is unavailable (emergency access)
const FALLBACK_USERS = [
  {
    username: 'hr-admin',
    password: '$2a$10$TMb3kwqITWg0NPTJgNGBKu6CndZ.YJdmj0A/RsTX.DPHiwMNhQPl.', // 'hrportal2025'
    displayName: 'HR Administrator',
    email: 'hr-admin@innovatech.local',
    groups: ['HR-Admins'],
    role: 'hr-admin'
  }
];

// Login with Active Directory credentials + fallback
router.post('/login',
  [
    body('username').notEmpty().trim(),
    body('password').notEmpty()
  ],
  async (req, res, next) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { username, password } = req.body;
      
      logger.info(`[AUTH] Login attempt for user: ${username}`);

      // Try LDAP authentication first if enabled
      const ldapEnabled = await ldapService.isEnabled();
      if (ldapEnabled) {
        try {
          const authResult = await ldapService.authenticate(username, password);
          
          if (authResult.success) {
            // Get user groups and details from AD
            const userDetails = await ldapService.getUserDetails(username);
            
            if (userDetails) {
              // Determine primary role based on groups
              let role = 'user';
              if (userDetails.groups.includes('HR-Admins')) role = 'hr-admin';
              else if (userDetails.groups.includes('IT-Admins')) role = 'it-admin';
              else if (userDetails.groups.includes('Dept-Managers')) role = 'manager';

              // Get user permissions based on group membership
              const permissions = getUserPermissions(userDetails.groups);

              // Generate JWT with user info and groups
              const token = jwt.sign(
                { 
                  username: userDetails.username,
                  displayName: userDetails.displayName,
                  email: userDetails.email,
                  groups: userDetails.groups,
                  role: role,
                  permissions: permissions,
                  authMethod: 'ldap'
                },
                process.env.JWT_SECRET || 'your-secret-key',
                { expiresIn: '8h' }
              );

              logger.info(`[AUTH] Successful LDAP login for ${username} (groups: ${userDetails.groups.join(', ')})`);

              return res.json({ 
                token, 
                user: {
                  username: userDetails.username,
                  displayName: userDetails.displayName,
                  email: userDetails.email,
                  role: role,
                  groups: userDetails.groups,
                  permissions: permissions,
                  authMethod: 'ldap'
                }
              });
            }
          }
        } catch (ldapError) {
          logger.error('[AUTH] LDAP authentication error:', ldapError.message);
          logger.info('[AUTH] Falling back to local authentication');
        }
      } else {
        logger.warn('[AUTH] LDAP is disabled, using fallback authentication');
      }

      // Fallback to local authentication if LDAP fails or is disabled
      const fallbackUser = FALLBACK_USERS.find(u => u.username === username);
      
      if (fallbackUser && await bcrypt.compare(password, fallbackUser.password)) {
        const permissions = getUserPermissions(fallbackUser.groups);
        
        const token = jwt.sign(
          { 
            username: fallbackUser.username,
            displayName: fallbackUser.displayName,
            email: fallbackUser.email,
            groups: fallbackUser.groups,
            role: fallbackUser.role,
            permissions: permissions,
            authMethod: 'fallback'
          },
          process.env.JWT_SECRET || 'your-secret-key',
          { expiresIn: '8h' }
        );

        logger.info(`[AUTH] Successful fallback login for ${username}`);

        return res.json({ 
          token, 
          user: {
            username: fallbackUser.username,
            displayName: fallbackUser.displayName,
            email: fallbackUser.email,
            role: fallbackUser.role,
            groups: fallbackUser.groups,
            permissions: permissions,
            authMethod: 'fallback'
          }
        });
      }

      // Authentication failed
      logger.warn(`[AUTH] Failed login attempt for user: ${username}`);
      return res.status(401).json({ 
        error: 'Invalid credentials',
        message: 'Authentication failed'
      });

    } catch (error) {
      logger.error('[AUTH] Login error:', error);
      next(error);
    }
  }
);

// Health check endpoint for LDAP
router.get('/health', async (req, res) => {
  try {
    const ldapHealth = await ldapService.healthCheck();
    res.json({
      status: 'ok',
      ldap: ldapHealth,
      fallbackAvailable: FALLBACK_USERS.length > 0
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// Verify token middleware
const verifyToken = (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];
  
  if (!token) {
    return res.status(403).json({ error: 'No token provided' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

router.get('/verify', verifyToken, (req, res) => {
  res.json({ valid: true, user: req.user });
});

module.exports = router;
module.exports.verifyToken = verifyToken;
