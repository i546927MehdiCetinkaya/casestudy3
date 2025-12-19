// Authentication Utility - JWT + RBAC Support
// Handles token storage, user info, and permission checking with graceful degradation

const TOKEN_KEY = 'auth_token';
const USER_KEY = 'auth_user';

/**
 * Check if user is authenticated
 */
export const isAuthenticated = () => {
  try {
    const token = localStorage.getItem(TOKEN_KEY);
    console.log('[Auth] isAuthenticated check - token exists:', !!token);
    if (!token) {
      console.log('[Auth] No token found');
      return false;
    }

    // Check if token is expired
    const payload = parseJWT(token);
    console.log('[Auth] Token payload:', payload);
    if (!payload || !payload.exp) {
      console.log('[Auth] Invalid payload or no expiry');
      return false;
    }

    const now = Date.now() / 1000;
    const isValid = payload.exp > now;
    console.log('[Auth] Token validity:', { exp: payload.exp, now, isValid, timeLeft: payload.exp - now });
    return isValid;
  } catch (error) {
    console.error('[Auth] Error checking authentication:', error);
    return false;
  }
};

/**
 * Get current user from localStorage
 */
export const getCurrentUser = () => {
  try {
    const userStr = localStorage.getItem(USER_KEY);
    if (!userStr) return null;

    return JSON.parse(userStr);
  } catch (error) {
    console.error('[Auth] Error getting current user:', error);
    return null;
  }
};

/**
 * Get JWT token
 */
export const getIdToken = () => {
  try {
    return localStorage.getItem(TOKEN_KEY);
  } catch (error) {
    console.error('[Auth] Error getting token:', error);
    return null;
  }
};

/**
 * Sign in - store token and user info
 */
export const signIn = (token, user) => {
  try {
    console.log('[Auth] Signing in user:', user.username);
    localStorage.setItem(TOKEN_KEY, token);
    localStorage.setItem(USER_KEY, JSON.stringify(user));
    console.log('[Auth] Token and user stored successfully');
    return true;
  } catch (error) {
    console.error('[Auth] Error signing in:', error);
    return false;
  }
};

/**
 * Sign out - clear auth data
 */
export const signOut = () => {
  try {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
    return true;
  } catch (error) {
    console.error('[Auth] Error signing out:', error);
    return false;
  }
};

/**
 * Check if user has specific permission
 */
export const hasPermission = (resource, action) => {
  try {
    const user = getCurrentUser();
    if (!user || !user.permissions) return false;

    const resourcePermissions = user.permissions[resource];
    if (!resourcePermissions || !Array.isArray(resourcePermissions)) {
      return false;
    }

    return resourcePermissions.includes(action) || resourcePermissions.includes('*');
  } catch (error) {
    console.error('[Auth] Error checking permission:', error);
    return false;
  }
};

/**
 * Check if user is in specific group
 */
export const isInGroup = (groupName) => {
  try {
    const user = getCurrentUser();
    if (!user || !user.groups || !Array.isArray(user.groups)) {
      return false;
    }

    return user.groups.includes(groupName);
  } catch (error) {
    console.error('[Auth] Error checking group membership:', error);
    return false;
  }
};

/**
 * Check if user is HR Admin (backwards compatibility)
 */
export const isHRAdmin = () => {
  return isInGroup('HR-Admins') || hasPermission('employees', 'create');
};

/**
 * Check if user is IT Admin
 */
export const isITAdmin = () => {
  return isInGroup('IT-Admins');
};

/**
 * Get user's role
 */
export const getUserRole = () => {
  try {
    const user = getCurrentUser();
    return user?.role || 'user';
  } catch (error) {
    console.error('[Auth] Error getting user role:', error);
    return 'user';
  }
};

/**
 * Get user's display name
 */
export const getDisplayName = () => {
  try {
    const user = getCurrentUser();
    return user?.displayName || user?.username || 'User';
  } catch (error) {
    console.error('[Auth] Error getting display name:', error);
    return 'User';
  }
};

/**
 * Get user's groups
 */
export const getUserGroups = () => {
  try {
    const user = getCurrentUser();
    return user?.groups || [];
  } catch (error) {
    console.error('[Auth] Error getting user groups:', error);
    return [];
  }
};

/**
 * Parse JWT token (helper function)
 */
const parseJWT = (token) => {
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch (error) {
    console.error('[Auth] Error parsing JWT:', error);
    return null;
  }
};

/**
 * Check authentication health
 */
export const checkAuthHealth = async () => {
  try {
    const response = await fetch('/api/auth/health');
    return await response.json();
  } catch (error) {
    console.error('[Auth] Error checking auth health:', error);
    return { status: 'error', ldap: { healthy: false } };
  }
};

export default {
  isAuthenticated,
  getCurrentUser,
  getIdToken,
  signIn,
  signOut,
  hasPermission,
  isInGroup,
  isHRAdmin,
  isITAdmin,
  getUserRole,
  getDisplayName,
  getUserGroups,
  checkAuthHealth
};
