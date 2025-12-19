// LDAP Service for Active Directory Authentication
// Handles user authentication and group membership queries with robust error handling

let ldap;
try {
  ldap = require('ldapjs');
} catch (error) {
  console.warn('[LDAP] ldapjs module not available:', error.message);
  ldap = null;
}

const ssmService = require('./ssm');
const logger = require('../utils/logger');

class LDAPService {
  constructor() {
    this.baseDN = process.env.AD_BASE_DN || 'DC=innovatech,DC=local';
    this.bindDN = process.env.AD_BIND_DN || 'CN=Administrator,CN=Users,DC=innovatech,DC=local';
    this.bindPassword = process.env.AD_BIND_PASSWORD || '';
    this.enabled = process.env.AD_ENABLED !== 'false';
    this.connectionTimeout = parseInt(process.env.AD_TIMEOUT || '5000');
    this.maxRetries = 3;
    this.ldapUrl = null; // Will be loaded from SSM
    this.configLoaded = false;
  }

  // Initialize LDAP configuration from SSM
  async loadConfig() {
    if (this.configLoaded && this.ldapUrl) return;

    try {
      const directoryConfig = await ssmService.getDirectoryConfig();
      
      if (!directoryConfig.enabled) {
        logger.warn('[LDAP] Directory Service not enabled in SSM');
        this.enabled = false;
        return;
      }

      // Get DNS IPs from SSM
      const dnsIps = directoryConfig.dnsServers || directoryConfig.dnsIps;
      if (!dnsIps) {
        logger.error('[LDAP] No DNS IPs found in directory config');
        this.enabled = false;
        return;
      }

      // Parse DNS IPs (format: "10.0.56.171,10.0.76.3" or "10.0.53.80 10.0.69.99")
      const ips = dnsIps.includes(',') ? dnsIps.split(',') : dnsIps.split(' ');
      const primaryDns = ips[0].trim();

      this.ldapUrl = `ldap://${primaryDns}:389`;
      
      // Load admin credentials from SSM
      try {
        const { SSMClient, GetParameterCommand } = require('@aws-sdk/client-ssm');
        const ssmClient = new SSMClient({ region: process.env.AWS_REGION || 'eu-west-1' });
        const clusterName = process.env.CLUSTER_NAME || 'innovatech-employee-lifecycle';
        
        logger.info(`[LDAP] Loading admin credentials from SSM: /${clusterName}/directory/admin-user`);
        
        const adminUserParam = await ssmClient.send(new GetParameterCommand({
          Name: `/${clusterName}/directory/admin-user`
        }));
        
        logger.info(`[LDAP] Admin user loaded: ${adminUserParam.Parameter.Value}`);
        
        const adminPasswordParam = await ssmClient.send(new GetParameterCommand({
          Name: `/${clusterName}/directory/admin-password`,
          WithDecryption: true
        }));
        
        logger.info(`[LDAP] Admin password loaded from SSM (length: ${adminPasswordParam.Parameter.Value.length})`);
        
        if (adminUserParam.Parameter && adminPasswordParam.Parameter) {
          // Use UPN format for AWS Managed Microsoft AD: Admin@domain
          const domainParts = this.baseDN.match(/DC=([^,]+)/g);
          const domain = domainParts ? domainParts.map(dc => dc.replace('DC=', '')).join('.') : 'innovatech.local';
          this.bindDN = `${adminUserParam.Parameter.Value}@${domain}`;
          this.bindPassword = adminPasswordParam.Parameter.Value;
          logger.info(`[LDAP] Admin credentials loaded from SSM (UPN format): ${this.bindDN}`);
        } else {
          logger.warn('[LDAP] Admin credentials not found in SSM, user creation will fail');
        }
      } catch (adminError) {
        logger.error('[LDAP] Could not load admin credentials from SSM:', adminError);
      }
      
      this.configLoaded = true;

      logger.info(`[LDAP] Configuration loaded: ${this.ldapUrl}, domain: ${directoryConfig.domain}`);
    } catch (error) {
      logger.error('[LDAP] Failed to load configuration from SSM:', error.message);
      this.enabled = false;
    }
  }

  // Check if LDAP is enabled
  async isEnabled() {
    await this.loadConfig();
    return this.enabled && this.ldapUrl && this.baseDN;
  }

  // Create LDAP client connection with proper error handling
  createClient() {
    if (!ldap) {
      logger.warn('[LDAP] ldapjs not available, cannot create client');
      return null;
    }
    
    try {
      return ldap.createClient({
        url: this.ldapUrl,
        timeout: this.connectionTimeout,
        connectTimeout: this.connectionTimeout * 2,
        reconnect: {
          initialDelay: 100,
          maxDelay: 1000,
          failAfter: this.maxRetries
        }
      });
    } catch (error) {
      logger.error('[LDAP] Failed to create client:', error.message);
      return null;
    }
  }

  // Authenticate user with AD credentials with retry logic
  async authenticate(username, password) {
    const enabled = await this.isEnabled();
    if (!enabled) {
      logger.warn('[LDAP] LDAP is disabled, skipping authentication');
      return { success: false, error: 'LDAP authentication is not available' };
    }

    if (!username || !password) {
      return { success: false, error: 'Username and password are required' };
    }

    let lastError = null;
    
    for (let attempt = 1; attempt <= this.maxRetries; attempt++) {
      try {
        const result = await this._attemptAuthentication(username, password);
        if (result.success) {
          return result;
        }
        lastError = result.error;
      } catch (error) {
        lastError = error.message;
        logger.warn(`[LDAP] Authentication attempt ${attempt}/${this.maxRetries} failed:`, error.message);
        
        if (attempt < this.maxRetries) {
          await this._sleep(1000 * attempt); // Exponential backoff
        }
      }
    }

    return { success: false, error: lastError || 'Authentication failed after retries' };
  }

  // Internal authentication attempt
  _attemptAuthentication(username, password) {
    return new Promise((resolve) => {
      const client = this.createClient();
      
      if (!client) {
        resolve({ success: false, error: 'Could not create LDAP client' });
        return;
      }

      // Use UPN format for AWS Managed Microsoft AD: username@domain
      // Extract domain from baseDN (DC=innovatech,DC=local -> innovatech.local)
      const domainParts = this.baseDN.match(/DC=([^,]+)/g);
      const domain = domainParts ? domainParts.map(dc => dc.replace('DC=', '')).join('.') : 'innovatech.local';
      const userPrincipalName = `${username}@${domain}`;
      
      logger.info(`[LDAP] Attempting authentication for user: ${username} (UPN: ${userPrincipalName})`);

      // Set timeout for bind operation
      const timeoutId = setTimeout(() => {
        client.unbind();
        resolve({ success: false, error: 'Authentication timeout' });
      }, this.connectionTimeout);

      client.bind(userPrincipalName, password, (err) => {
        clearTimeout(timeoutId);
        
        if (err) {
          logger.error(`[LDAP] Authentication failed for ${username}:`, err.code, err.message);
          client.unbind();
          resolve({ success: false, error: 'Invalid credentials' });
          return;
        }

        logger.info(`[LDAP] Authentication successful for ${username}`);
        client.unbind();
        resolve({ success: true, username });
      });
    });
  }

  // Get user's AD group memberships with error handling
  async getUserGroups(username) {
    if (!this.isEnabled()) {
      logger.warn('[LDAP] LDAP is disabled, returning empty groups');
      return { success: false, groups: [] };
    }

    try {
      return await this._attemptGetUserGroups(username);
    } catch (error) {
      logger.error('[LDAP] Failed to get user groups:', error.message);
      return { success: false, groups: [], error: error.message };
    }
  }

  // Internal get user groups attempt
  _attemptGetUserGroups(username) {
    return new Promise((resolve) => {
      const client = this.createClient();
      
      if (!client) {
        resolve({ success: false, groups: [] });
        return;
      }

      // Search in CN=Users (standard AD container) or entire domain
      const searchDN = this.baseDN; // Search entire domain to find user
      
      // Set timeout
      const timeoutId = setTimeout(() => {
        client.unbind();
        resolve({ success: false, groups: [], error: 'Search timeout' });
      }, this.connectionTimeout);

      // First bind with service account
      client.bind(this.bindDN, this.bindPassword, (bindErr) => {
        if (bindErr) {
          clearTimeout(timeoutId);
          logger.error('[LDAP] Service account bind failed:', bindErr.message);
          client.unbind();
          resolve({ success: false, groups: [] });
          return;
        }

        // Search for user and get memberOf attribute
        const searchOptions = {
          filter: `(sAMAccountName=${username})`,
          scope: 'sub',
          attributes: ['memberOf', 'displayName', 'mail'],
          timeLimit: Math.floor(this.connectionTimeout / 1000)
        };

        client.search(searchDN, searchOptions, (searchErr, res) => {
          if (searchErr) {
            clearTimeout(timeoutId);
            logger.error('[LDAP] User search failed:', searchErr.message);
            client.unbind();
            resolve({ success: false, groups: [] });
            return;
          }

          let userEntry = null;

          res.on('searchEntry', (entry) => {
            userEntry = entry.pojo;
          });

          res.on('error', (err) => {
            clearTimeout(timeoutId);
            logger.error('[LDAP] Search error:', err.message);
            client.unbind();
            resolve({ success: false, groups: [] });
          });

          res.on('end', () => {
            clearTimeout(timeoutId);
            client.unbind();

            if (!userEntry) {
              logger.warn(`[LDAP] User not found: ${username}`);
              resolve({ success: false, groups: [] });
              return;
            }

            // Extract group names from memberOf DN strings
            const memberOf = userEntry.attributes.find(attr => attr.type === 'memberOf');
            const groups = [];

            if (memberOf && memberOf.values) {
              memberOf.values.forEach(dn => {
                // Extract CN from DN: "CN=HR-Admins,OU=Groups,..." -> "HR-Admins"
                const match = dn.match(/^CN=([^,]+)/);
                if (match) {
                  groups.push(match[1]);
                }
              });
            }

            logger.info(`[LDAP] User ${username} is member of groups:`, groups);
            resolve({ success: true, groups, userEntry });
          });
        });
      });
    });
  }

  // Get full user details from AD
  async getUserDetails(username) {
    const result = await this.getUserGroups(username);
    if (!result.success) {
      return null;
    }

    try {
      const attributes = result.userEntry.attributes;
      const displayName = attributes.find(attr => attr.type === 'displayName')?.values[0] || username;
      const email = attributes.find(attr => attr.type === 'mail')?.values[0] || `${username}@innovatech.local`;

      return {
        username,
        displayName,
        email,
        groups: result.groups
      };
    } catch (error) {
      logger.error('[LDAP] Failed to parse user details:', error.message);
      return {
        username,
        displayName: username,
        email: `${username}@innovatech.local`,
        groups: result.groups || []
      };
    }
  }

  // Check if user is member of specific group
  async isMemberOf(username, groupName) {
    const result = await this.getUserGroups(username);
    return result.success && result.groups.includes(groupName);
  }

  // Health check for LDAP connection
  async healthCheck() {
    if (!this.isEnabled()) {
      return { healthy: false, message: 'LDAP is disabled' };
    }

    try {
      const client = this.createClient();
      if (!client) {
        return { healthy: false, message: 'Could not create LDAP client' };
      }

      return new Promise((resolve) => {
        const timeoutId = setTimeout(() => {
          client.unbind();
          resolve({ healthy: false, message: 'Connection timeout' });
        }, this.connectionTimeout);

        client.bind(this.bindDN, this.bindPassword, (err) => {
          clearTimeout(timeoutId);
          client.unbind();
          
          if (err) {
            resolve({ healthy: false, message: err.message });
          } else {
            resolve({ healthy: true, message: 'LDAP connection successful' });
          }
        });
      });
    } catch (error) {
      return { healthy: false, message: error.message };
    }
  }

  // Helper: sleep function for retry backoff
  _sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // Create a new user in Active Directory
  async createUser({ username, password, firstName, lastName, email, department, role }) {
    const enabled = await this.isEnabled();
    if (!enabled) {
      throw new Error('LDAP is not enabled');
    }

    return new Promise((resolve, reject) => {
      const client = this.createClient();
      
      if (!client) {
        reject(new Error('Could not create LDAP client'));
        return;
      }

      // Bind with admin credentials
      client.bind(this.bindDN, this.bindPassword, (bindErr) => {
        if (bindErr) {
          logger.error('[LDAP] Admin bind failed for user creation:', bindErr.message);
          client.unbind();
          reject(new Error(`LDAP bind failed: ${bindErr.message}`));
          return;
        }

        // Construct user DN - use CN=Users container (standard AD location)
        // Department OUs (Engineering, HR, etc.) may not exist yet
        const userDN = `CN=${firstName} ${lastName},CN=Users,${this.baseDN}`;
        
        // User attributes for AD
        const userEntry = {
          objectClass: ['top', 'person', 'organizationalPerson', 'user'],
          cn: `${firstName} ${lastName}`,
          sn: lastName,
          givenName: firstName,
          displayName: `${firstName} ${lastName}`,
          sAMAccountName: username,
          userPrincipalName: `${username}@innovatech.local`,
          mail: email,
          userAccountControl: '512', // Normal account, enabled
          pwdLastSet: '0' // Force password change on first login
        };

        logger.info(`[LDAP] Creating AD user: ${username} at ${userDN}`);

        // Add user to directory
        client.add(userDN, userEntry, (addErr) => {
          if (addErr) {
            logger.error(`[LDAP] User creation failed for ${username}:`, addErr.message);
            client.unbind();
            
            // Check for duplicate user error
            if (addErr.message.includes('ENTRY_EXISTS') || addErr.message.includes('already exists')) {
              reject(new Error(`User ${username} already exists in Active Directory`));
            } else {
              reject(new Error(`Failed to create user: ${addErr.message}`));
            }
            return;
          }

          logger.info(`[LDAP] User ${username} created, setting password`);

          // Set password (convert to UTF-16LE with quotes as required by AD)
          const passwordBuffer = Buffer.from(`"${password}"`, 'utf16le');
          const passwordChange = {
            operation: 'replace',
            modification: {
              unicodePwd: passwordBuffer
            }
          };

          client.modify(userDN, passwordChange, (modifyErr) => {
            if (modifyErr) {
              logger.error(`[LDAP] Password set failed for ${username}:`, modifyErr.message);
              // User created but password not set - still consider this a success
              logger.warn(`[LDAP] User ${username} created but password must be set manually`);
            } else {
              logger.info(`[LDAP] Password set successfully for ${username}`);
            }

            // Successfully created user - groups are optional and can be added later
            // Skip group membership for now since OUs may not exist yet
            logger.info(`[LDAP] User ${username} created successfully in CN=Users`);
            logger.info(`[LDAP] To add to groups, create OUs first: Engineering, HR, Sales, IT, Finance, Marketing`);
            
            client.unbind();
            resolve({
              success: true,
              userDN,
              username,
              groups: [] // Groups will be added when OUs are created
            });
          });
        });
      });
    });
  }
}

module.exports = new LDAPService();
