// API Utility - Axios wrapper with JWT auth + error handling
// Handles authentication, retries, and RBAC error responses

import axios from 'axios';
import { getIdToken, signOut } from '../auth/auth';

// Use relative path - nginx will proxy /api/* to backend
const API_BASE_URL = process.env.REACT_APP_API_URL || '/api';

// Create axios instance
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000, // 30 seconds
  headers: {
    'Content-Type': 'application/json'
  }
});

// Request interceptor - add JWT token
api.interceptors.request.use(
  (config) => {
    try {
      const token = getIdToken();
      console.log('[API] Request:', config.method?.toUpperCase(), config.url, '- Token:', token ? 'YES' : 'NO');
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    } catch (error) {
      console.error('[API] Error adding auth token:', error);
    }
    return config;
  },
  (error) => {
    console.error('[API] Request interceptor error:', error);
    return Promise.reject(error);
  }
);

// Response interceptor - handle errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    // Log error for debugging
    console.error('[API] Response error:', {
      url: error.config?.url,
      method: error.config?.method,
      status: error.response?.status,
      message: error.response?.data?.error || error.message
    });

    // Handle specific error cases
    if (error.response) {
      const { status, data } = error.response;

      switch (status) {
        case 401:
          // Unauthorized - token invalid or expired
          console.error('[API] 401 Unauthorized:', {
            url: error.config?.url,
            hasAuthHeader: !!error.config?.headers?.Authorization,
            responseData: data
          });
          
          // Only sign out if this is a login endpoint failure
          // For other endpoints, let the component handle the error
          if (error.config?.url?.includes('/auth/login')) {
            console.warn('[API] Login failed, not signing out (already logged out)');
          } else {
            console.warn('[API] API call unauthorized - check token validity');
            // Don't auto-signout - let user try again or see the error
            // signOut();
            // window.location.href = '/login';
          }
          return Promise.reject(new Error(data.error || 'Unauthorized. Please check your permissions.'));

        case 403:
          // Forbidden - user doesn't have permission
          const permissionError = new Error(
            data.error || 'You do not have permission to perform this action.'
          );
          permissionError.code = 'PERMISSION_DENIED';
          return Promise.reject(permissionError);

        case 404:
          return Promise.reject(new Error(data.error || 'Resource not found.'));

        case 409:
          return Promise.reject(new Error(data.error || 'Resource conflict.'));

        case 500:
        case 502:
        case 503:
          return Promise.reject(
            new Error('Server error. Please try again later.')
          );

        default:
          return Promise.reject(
            new Error(data.error || `Request failed with status ${status}`)
          );
      }
    } else if (error.request) {
      // Request made but no response received
      console.error('[API] No response received:', error.request);
      return Promise.reject(
        new Error('Network error. Please check your connection.')
      );
    } else {
      // Error during request setup
      return Promise.reject(new Error(error.message || 'Request failed'));
    }
  }
);

// Authentication API
export const auth = {
  login: async (username, password) => {
    try {
      const response = await api.post('/auth/login', { username, password });
      return response.data;
    } catch (error) {
      console.error('[API] Login error:', error);
      throw error;
    }
  },

  health: async () => {
    try {
      const response = await api.get('/auth/health');
      return response.data;
    } catch (error) {
      console.error('[API] Health check error:', error);
      return { status: 'error', ldap: { healthy: false } };
    }
  }
};

// Employees API
export const employees = {
  getAll: async () => {
    try {
      const response = await api.get('/employees');
      return response.data;
    } catch (error) {
      console.error('[API] Get employees error:', error);
      throw error;
    }
  },

  getById: async (id) => {
    try {
      const response = await api.get(`/employees/${id}`);
      return response.data;
    } catch (error) {
      console.error('[API] Get employee error:', error);
      throw error;
    }
  },

  create: async (employee) => {
    try {
      const response = await api.post('/employees', employee);
      return response.data;
    } catch (error) {
      console.error('[API] Create employee error:', error);
      throw error;
    }
  },

  update: async (id, employee) => {
    try {
      const response = await api.put(`/employees/${id}`, employee);
      return response.data;
    } catch (error) {
      console.error('[API] Update employee error:', error);
      throw error;
    }
  },

  delete: async (id) => {
    try {
      const response = await api.delete(`/employees/${id}`);
      return response.data;
    } catch (error) {
      console.error('[API] Delete employee error:', error);
      throw error;
    }
  }
};

// Workspaces API
export const workspaces = {
  getAll: async () => {
    try {
      const response = await api.get('/workspaces');
      return response.data;
    } catch (error) {
      console.error('[API] Get workspaces error:', error);
      throw error;
    }
  },

  provision: async (employeeId) => {
    try {
      const response = await api.post(`/workspaces/provision/${employeeId}`);
      return response.data;
    } catch (error) {
      console.error('[API] Provision workspace error:', error);
      throw error;
    }
  },

  delete: async (employeeId) => {
    try {
      const response = await api.delete(`/workspaces/${employeeId}`);
      return response.data;
    } catch (error) {
      console.error('[API] Delete workspace error:', error);
      throw error;
    }
  }
};

export default api;
