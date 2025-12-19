// RBAC Middleware - Role-Based Access Control
// Enforces permissions based on Active Directory group membership with graceful degradation

const logger = require('../utils/logger');

// Permission matrix: AD Group -> Resource permissions
const ROLE_PERMISSIONS = {
  'HR-Admins': {
    employees: ['create', 'read', 'update', 'delete'],
    workspaces: ['create', 'read', 'delete'],
    monitoring: []
  },
  'IT-Admins': {
    employees: [],
    workspaces: ['create', 'read', 'delete'],
    monitoring: ['read']
  },
  'Dept-Managers': {
    employees: ['read'],
    workspaces: ['read'],
    monitoring: []
  },
  'Engineering': {
    employees: ['read'],
    workspaces: ['read'],
    monitoring: []
  }
};

// Check if user has permission for resource + action
function hasPermission(userGroups, resource, action) {
  // If no groups specified, deny access
  if (!userGroups || !Array.isArray(userGroups) || userGroups.length === 0) {
    return false;
  }

  // Check each group the user is a member of
  for (const group of userGroups) {
    const permissions = ROLE_PERMISSIONS[group];
    if (!permissions) continue;

    const resourcePermissions = permissions[resource];
    if (!resourcePermissions) continue;

    // Check if group has required action permission
    if (resourcePermissions.includes(action) || resourcePermissions.includes('*')) {
      return true;
    }
  }

  return false;
}

// Middleware factory: requirePermission(resource, action)
function requirePermission(resource, action) {
  return (req, res, next) => {
    try {
      // Check if user is authenticated
      if (!req.user) {
        logger.warn(`[RBAC] No user found in request for ${resource}:${action}`);
        return res.status(401).json({
          error: 'Unauthorized',
          message: 'You must be logged in to perform this action'
        });
      }

      // Extract user groups from JWT (set by auth middleware)
      const userGroups = req.user?.groups || [];
      const username = req.user?.username || 'unknown';

      logger.info(`[RBAC] Checking permission: ${username} -> ${resource}:${action}`);

      if (!hasPermission(userGroups, resource, action)) {
        logger.warn(`[RBAC] Access denied: ${username} (groups: ${userGroups.join(', ')}) -> ${resource}:${action}`);
        return res.status(403).json({
          error: 'Forbidden',
          message: `You do not have permission to ${action} ${resource}`,
          requiredPermission: `${resource}:${action}`,
          yourGroups: userGroups,
          hint: 'Contact your administrator to request access'
        });
      }

      logger.info(`[RBAC] Access granted: ${username} -> ${resource}:${action}`);
      next();
    } catch (error) {
      logger.error('[RBAC] Error checking permissions:', error);
      // On error, deny access for security
      return res.status(500).json({
        error: 'Internal Server Error',
        message: 'Could not verify permissions'
      });
    }
  };
}

// Get all permissions for user's groups
function getUserPermissions(userGroups) {
  const permissions = {
    employees: [],
    workspaces: [],
    monitoring: []
  };

  if (!userGroups || !Array.isArray(userGroups)) {
    return permissions;
  }

  try {
    userGroups.forEach(group => {
      const groupPermissions = ROLE_PERMISSIONS[group];
      if (!groupPermissions) return;

      Object.keys(groupPermissions).forEach(resource => {
        const actions = groupPermissions[resource];
        if (!Array.isArray(actions)) return;
        
        permissions[resource] = [...new Set([...permissions[resource], ...actions])];
      });
    });
  } catch (error) {
    logger.error('[RBAC] Error getting user permissions:', error);
  }

  return permissions;
}

// Check if RBAC is properly configured
function isConfigured() {
  return Object.keys(ROLE_PERMISSIONS).length > 0;
}

module.exports = {
  requirePermission,
  hasPermission,
  getUserPermissions,
  ROLE_PERMISSIONS,
  isConfigured
};
