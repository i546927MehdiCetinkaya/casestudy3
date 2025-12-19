/**
 * AWS Directory Service Integration
 * Manages employees in AWS Managed Microsoft AD
 * Uses IAM Roles instead of IAM Users for access control
 * Note: AWS SDK Directory Service does NOT support CreateUser - must use LDAP
 */

const { DirectoryServiceClient, DescribeDirectoriesCommand } = require('@aws-sdk/client-directory-service');
const ssmService = require('./ssm');
const ldapService = require('./ldap');
const logger = require('../utils/logger');

// Initialize Directory Service client
const dsClient = new DirectoryServiceClient({ region: process.env.AWS_REGION || 'eu-west-1' });

// Directory configuration (loaded from SSM)
let directoryConfig = null;

/**
 * Initialize directory configuration from SSM
 */
async function initializeConfig() {
  if (directoryConfig) return directoryConfig;

  try {
    const config = await ssmService.getDirectoryConfig();
    directoryConfig = config;
    logger.info('Directory Service configuration loaded');
    return directoryConfig;
  } catch (error) {
    logger.warn('Directory Service not configured, using fallback mode');
    directoryConfig = { enabled: false };
    return directoryConfig;
  }
}

/**
 * Check if Directory Service is enabled
 */
async function isEnabled() {
  const config = await initializeConfig();
  return config.enabled && config.directoryId;
}

/**
 * Create a user in AWS Directory Service
 * @param {Object} employee - Employee details
 * @returns {Object} Directory user details
 */
async function createDirectoryUser(employee) {
  const config = await initializeConfig();
  
  if (!config.enabled) {
    logger.info('Directory Service disabled, skipping user creation');
    return { success: false, reason: 'Directory Service not enabled' };
  }

  try {
    const username = generateUsername(employee);
    const tempPassword = generateSecurePassword();
    
    // Note: AWS SDK DirectoryService does NOT have CreateUser command
    // AWS Managed AD requires LDAP or manual user creation via console
    
    const ldapEnabled = await ldapService.isEnabled();
    if (ldapEnabled) {
      logger.info(`Creating AD user via LDAP for ${employee.employeeId}: ${username}`);
      
      try {
        await ldapService.createUser({
          username,
          password: tempPassword,
          firstName: employee.firstName,
          lastName: employee.lastName,
          email: employee.email,
          department: employee.department,
          role: employee.role
        });
        
        logger.info(`AD user created successfully via LDAP: ${username}@${config.domain}`);
        
        // Store temporary password in SSM for email notification
        await ssmService.storeTemporaryPassword(employee.employeeId, tempPassword);
        
      } catch (ldapError) {
        logger.error(`LDAP user creation failed for ${username}:`, {
          message: ldapError.message,
          code: ldapError.code,
          name: ldapError.name,
          stack: ldapError.stack,
          ldapError: ldapError.lde_message || 'No LDAP error details'
        });
        logger.warn(`AD user creation failed - user ${username} must be created manually in AWS Directory Service console`);
        // Continue to create SSM mapping even if LDAP fails
        // This allows manual AD creation later
      }
    } else {
      logger.warn('LDAP not enabled, user created in DB only (manual AD creation required)');
    }
    
    // Store user mapping in SSM for tracking
    await ssmService.storeDirectoryUserMapping(employee.employeeId, {
      username,
      displayName: `${employee.firstName} ${employee.lastName}`,
      email: employee.email,
      department: employee.department,
      role: employee.role,
      iamRole: getRoleForDepartment(employee.department),
      createdAt: new Date().toISOString()
    });

    logger.info(`Directory user mapping created for ${employee.employeeId}: ${username}`);

    return {
      success: true,
      username,
      tempPassword,
      domain: config.domain,
      iamRole: getRoleForDepartment(employee.department),
      loginUrl: `https://${config.accessUrl || 'console.aws.amazon.com'}/`
    };
  } catch (error) {
    logger.error(`Failed to create directory user for ${employee.employeeId}:`, error);
    throw error;
  }
}

/**
 * Delete a user from AWS Directory Service
 * @param {string} employeeId - Employee ID
 */
async function deleteDirectoryUser(employeeId) {
  const config = await initializeConfig();
  
  if (!config.enabled) {
    logger.info('Directory Service disabled, skipping user deletion');
    return { success: false, reason: 'Directory Service not enabled' };
  }

  try {
    // Get user mapping
    const userMapping = await ssmService.getDirectoryUserMapping(employeeId);
    
    if (!userMapping) {
      logger.warn(`No directory user mapping found for ${employeeId}`);
      return { success: false, reason: 'User not found' };
    }

    // Delete user mapping from SSM
    await ssmService.deleteDirectoryUserMapping(employeeId);

    logger.info(`Directory user mapping deleted for ${employeeId}`);

    return { success: true, username: userMapping.username };
  } catch (error) {
    logger.error(`Failed to delete directory user for ${employeeId}:`, error);
    throw error;
  }
}

/**
 * Reset user password in Directory Service
 * @param {string} employeeId - Employee ID
 * @returns {Object} New password details
 */
async function resetUserPassword(employeeId) {
  const config = await initializeConfig();
  
  if (!config.enabled) {
    return { success: false, reason: 'Directory Service not enabled' };
  }

  try {
    const userMapping = await ssmService.getDirectoryUserMapping(employeeId);
    
    if (!userMapping) {
      return { success: false, reason: 'User not found' };
    }

    const newPassword = generateSecurePassword();

    // Store new temporary password in SSM
    await ssmService.storeTemporaryPassword(employeeId, newPassword);

    logger.info(`Password reset initiated for ${employeeId}`);

    return {
      success: true,
      username: userMapping.username,
      tempPassword: newPassword
    };
  } catch (error) {
    logger.error(`Failed to reset password for ${employeeId}:`, error);
    throw error;
  }
}

/**
 * Get IAM Role ARN for a department
 * @param {string} department - Department name
 * @returns {string} IAM Role name to assume
 */
function getRoleForDepartment(department) {
  const roleMapping = {
    'IT': 'infra-role',
    'Infrastructure': 'infra-role',
    'DevOps': 'infra-role',
    'Engineering': 'developer-role',
    'Development': 'developer-role',
    'Software': 'developer-role',
    'HR': 'hr-role',
    'Human Resources': 'hr-role',
    'Management': 'manager-role',
    'Executive': 'manager-role',
    'Admin': 'admin-role',
    'Administration': 'admin-role'
  };

  return roleMapping[department] || 'developer-role'; // Default to developer role
}

/**
 * Get all department roles and their permissions
 */
function getDepartmentRoles() {
  return {
    'infra-role': {
      name: 'Infrastructure Team',
      description: 'EKS cluster access, EC2 read, CloudWatch monitoring',
      departments: ['IT', 'Infrastructure', 'DevOps']
    },
    'developer-role': {
      name: 'Developer',
      description: 'ECR access, CodeBuild, CloudWatch logs',
      departments: ['Engineering', 'Development', 'Software']
    },
    'hr-role': {
      name: 'HR Team',
      description: 'Employee data management, workspace read access',
      departments: ['HR', 'Human Resources']
    },
    'manager-role': {
      name: 'Manager',
      description: 'Read-only access to employee and workspace data',
      departments: ['Management', 'Executive']
    },
    'admin-role': {
      name: 'Administrator',
      description: 'Full access to all resources',
      departments: ['Admin', 'Administration']
    }
  };
}

/**
 * Generate username from employee details
 */
function generateUsername(employee) {
  const firstName = employee.firstName.toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z]/g, '');
  
  const lastName = employee.lastName.toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z]/g, '');
  
  // Format: firstname.lastname (e.g., john.doe)
  return `${firstName}.${lastName}`.substring(0, 20);
}

/**
 * Generate a secure password meeting AD complexity requirements
 */
function generateSecurePassword() {
  const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const lowercase = 'abcdefghijklmnopqrstuvwxyz';
  const numbers = '0123456789';
  const special = '!@#$%^&*';
  
  let password = '';
  
  // Ensure at least one of each type
  password += uppercase[Math.floor(Math.random() * uppercase.length)];
  password += lowercase[Math.floor(Math.random() * lowercase.length)];
  password += numbers[Math.floor(Math.random() * numbers.length)];
  password += special[Math.floor(Math.random() * special.length)];
  
  // Fill remaining with random chars
  const allChars = uppercase + lowercase + numbers + special;
  for (let i = password.length; i < 16; i++) {
    password += allChars[Math.floor(Math.random() * allChars.length)];
  }
  
  // Shuffle the password
  return password.split('').sort(() => Math.random() - 0.5).join('');
}

/**
 * Get directory information
 */
async function getDirectoryInfo() {
  const config = await initializeConfig();
  
  if (!config.enabled || !config.directoryId) {
    return { enabled: false };
  }

  try {
    const command = new DescribeDirectoriesCommand({
      DirectoryIds: [config.directoryId]
    });
    
    const response = await dsClient.send(command);
    
    if (response.DirectoryDescriptions && response.DirectoryDescriptions.length > 0) {
      const directory = response.DirectoryDescriptions[0];
      return {
        enabled: true,
        directoryId: directory.DirectoryId,
        name: directory.Name,
        shortName: directory.ShortName,
        type: directory.Type,
        stage: directory.Stage,
        dnsIpAddresses: directory.DnsIpAddrs,
        accessUrl: directory.AccessUrl
      };
    }
    
    return { enabled: false };
  } catch (error) {
    logger.error('Failed to get directory info:', error);
    return { enabled: false, error: error.message };
  }
}

module.exports = {
  isEnabled,
  createDirectoryUser,
  deleteDirectoryUser,
  resetUserPassword,
  getRoleForDepartment,
  getDepartmentRoles,
  getDirectoryInfo,
  generateUsername,
  generateSecurePassword
};
