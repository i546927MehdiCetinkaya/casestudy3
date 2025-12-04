import {
  CognitoUserPool,
  CognitoUser,
  AuthenticationDetails,
} from 'amazon-cognito-identity-js';

// Cognito configuration - loaded from environment or defaults
const poolData = {
  UserPoolId: process.env.REACT_APP_COGNITO_USER_POOL_ID || 'eu-west-1_w3KLan98g',
  ClientId: process.env.REACT_APP_COGNITO_CLIENT_ID || '7af9qsukj9ibauku7vi1g5cd3',
};

const userPool = new CognitoUserPool(poolData);

// Sign in user
export const signIn = (email, password) => {
  return new Promise((resolve, reject) => {
    const authenticationDetails = new AuthenticationDetails({
      Username: email,
      Password: password,
    });

    const cognitoUser = new CognitoUser({
      Username: email,
      Pool: userPool,
    });

    cognitoUser.authenticateUser(authenticationDetails, {
      onSuccess: (result) => {
        const idToken = result.getIdToken().getJwtToken();
        const accessToken = result.getAccessToken().getJwtToken();
        const refreshToken = result.getRefreshToken().getToken();
        
        // Decode ID token to get user info
        const payload = JSON.parse(atob(idToken.split('.')[1]));
        
        const user = {
          email: payload.email,
          name: payload.name || payload.email,
          groups: payload['cognito:groups'] || [],
          idToken,
          accessToken,
          refreshToken,
        };
        
        // Store tokens
        localStorage.setItem('idToken', idToken);
        localStorage.setItem('accessToken', accessToken);
        localStorage.setItem('refreshToken', refreshToken);
        localStorage.setItem('user', JSON.stringify(user));
        
        resolve(user);
      },
      onFailure: (err) => {
        reject(err);
      },
      newPasswordRequired: (userAttributes) => {
        // Handle new password required (first login)
        reject({ code: 'NewPasswordRequired', userAttributes });
      },
    });
  });
};

// Sign out user
export const signOut = () => {
  const cognitoUser = userPool.getCurrentUser();
  if (cognitoUser) {
    cognitoUser.signOut();
  }
  localStorage.removeItem('idToken');
  localStorage.removeItem('accessToken');
  localStorage.removeItem('refreshToken');
  localStorage.removeItem('user');
};

// Get current user from storage
export const getCurrentUser = () => {
  const userStr = localStorage.getItem('user');
  if (userStr) {
    return JSON.parse(userStr);
  }
  return null;
};

// Get current session token
export const getIdToken = () => {
  return localStorage.getItem('idToken');
};

// Check if user is authenticated
export const isAuthenticated = () => {
  const token = getIdToken();
  if (!token) return false;
  
  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    const exp = payload.exp * 1000; // Convert to milliseconds
    return Date.now() < exp;
  } catch {
    return false;
  }
};

// Check if user has specific role/group
export const hasRole = (role) => {
  const user = getCurrentUser();
  if (!user || !user.groups) return false;
  return user.groups.includes(role);
};

// Check if user is HR Admin
export const isHRAdmin = () => hasRole('HR-Admin');

// Check if user is HR Manager
export const isHRManager = () => hasRole('HR-Manager') || hasRole('HR-Admin');

// Check if user is HR Staff
export const isHRStaff = () => hasRole('HR-Staff') || hasRole('HR-Manager') || hasRole('HR-Admin');
