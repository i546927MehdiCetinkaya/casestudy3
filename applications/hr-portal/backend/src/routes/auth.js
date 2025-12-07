const express = require('express');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const ldapService = require('../services/ldap');
const { getUserPermissions } = require('../middleware/rbac');
const logger = require('../utils/logger');

const router = express.Router();

// Login with Active Directory credentials
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

      // Authenticate against Active Directory
      const authResult = await ldapService.authenticate(username, password);
      
      if (!authResult.success) {
        logger.warn(`[AUTH] Failed login attempt for user: ${username}`);
        return res.status(401).json({ 
          error: 'Invalid credentials',
          message: 'Unable to authenticate with Active Directory'
        });
      }

      // Get user groups and details from AD
      const userDetails = await ldapService.getUserDetails(username);
      
      if (!userDetails) {
        logger.error(`[AUTH] Could not retrieve user details for: ${username}`);
        return res.status(500).json({ 
          error: 'Authentication error',
          message: 'Could not retrieve user information'
        });
      }

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
          permissions: permissions
        },
        process.env.JWT_SECRET || 'your-secret-key',
        { expiresIn: '8h' }
      );

      logger.info(`[AUTH] Successful login for ${username} (groups: ${userDetails.groups.join(', ')})`);

      res.json({ 
        token, 
        user: {
          username: userDetails.username,
          displayName: userDetails.displayName,
          email: userDetails.email,
          role: role,
          groups: userDetails.groups,
          permissions: permissions
        }
      });
    } catch (error) {
      logger.error('[AUTH] Login error:', error);
      next(error);
    }
  }
);

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
