const k8s = require('@kubernetes/client-node');
const { v4: uuidv4 } = require('uuid');
const dynamodbService = require('./dynamodb');
const logger = require('../utils/logger');

const kc = new k8s.KubeConfig();
kc.loadFromCluster(); // Load in-cluster config when running in K8s

const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
const k8sAppsApi = kc.makeApiClient(k8s.AppsV1Api);
const k8sNetworkingApi = kc.makeApiClient(k8s.NetworkingV1Api);

const WORKSPACE_NAMESPACE = 'workspaces';
const ECR_REGISTRY = process.env.ECR_REGISTRY || 'ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com';

/**
 * Provision a new workspace for an employee
 */
async function provisionWorkspace(employee) {
  const workspaceId = uuidv4();
  const workspaceName = `${employee.firstName}-${employee.lastName}`.toLowerCase().replace(/\s+/g, '-');
  const password = generateSecurePassword();

  try {
    // 1. Create PersistentVolumeClaim
    await createPVC(workspaceName);
    
    // 2. Create Secret for workspace credentials
    await createSecret(workspaceName, password);
    
    // 3. Create Pod for workspace
    await createPod(workspaceName, employee, workspaceId);
    
    // 4. Create Service
    await createService(workspaceName);
    
    // 5. Create Ingress
    const workspaceUrl = await createIngress(workspaceName);
    
    // 6. Save workspace metadata to DynamoDB
    const workspace = {
      workspaceId,
      employeeId: employee.employeeId,
      name: workspaceName,
      url: workspaceUrl,
      status: 'provisioning',
      createdAt: new Date().toISOString(),
      credentials: {
        username: 'coder',
        // In production, store password securely or send via email
      }
    };
    
    await dynamodbService.createWorkspace(workspace);
    
    logger.info(`Workspace provisioned: ${workspaceId} for employee ${employee.employeeId}`);
    return workspace;
  } catch (error) {
    logger.error(`Error provisioning workspace for ${employee.employeeId}:`, error);
    // Cleanup on error
    await cleanupWorkspace(workspaceName);
    throw error;
  }
}

/**
 * Deprovision workspace for an employee
 */
async function deprovisionWorkspace(employeeId) {
  try {
    const workspace = await dynamodbService.getWorkspaceByEmployee(employeeId);
    if (!workspace) {
      logger.warn(`No workspace found for employee ${employeeId}`);
      return;
    }

    const workspaceName = workspace.name;
    
    // Delete Kubernetes resources
    await cleanupWorkspace(workspaceName);
    
    // Delete from DynamoDB
    await dynamodbService.deleteWorkspace(workspace.workspaceId);
    
    logger.info(`Workspace deprovisioned: ${workspace.workspaceId} for employee ${employeeId}`);
  } catch (error) {
    logger.error(`Error deprovisioning workspace for ${employeeId}:`, error);
    throw error;
  }
}

/**
 * Get workspace status
 */
async function getWorkspaceStatus(workspaceId) {
  try {
    const workspace = await dynamodbService.getWorkspaceByEmployee(workspaceId);
    if (!workspace) {
      return { status: 'not_found' };
    }

    // Check pod status
    const podResponse = await k8sApi.readNamespacedPod(workspace.name, WORKSPACE_NAMESPACE);
    const pod = podResponse.body;
    
    return {
      status: pod.status.phase.toLowerCase(),
      ready: pod.status.conditions?.find(c => c.type === 'Ready')?.status === 'True',
      url: workspace.url
    };
  } catch (error) {
    logger.error(`Error getting workspace status for ${workspaceId}:`, error);
    return { status: 'error', error: error.message };
  }
}

// Helper functions
async function createPVC(name) {
  const pvc = {
    apiVersion: 'v1',
    kind: 'PersistentVolumeClaim',
    metadata: {
      name: `${name}-pvc`,
      namespace: WORKSPACE_NAMESPACE
    },
    spec: {
      accessModes: ['ReadWriteOnce'],
      storageClassName: 'workspace-storage',
      resources: {
        requests: {
          storage: '10Gi'
        }
      }
    }
  };

  await k8sApi.createNamespacedPersistentVolumeClaim(WORKSPACE_NAMESPACE, pvc);
}

async function createSecret(name, password) {
  const secret = {
    apiVersion: 'v1',
    kind: 'Secret',
    metadata: {
      name: `${name}-secret`,
      namespace: WORKSPACE_NAMESPACE
    },
    type: 'Opaque',
    stringData: {
      password: password
    }
  };

  await k8sApi.createNamespacedSecret(WORKSPACE_NAMESPACE, secret);
}

async function createPod(name, employee, workspaceId) {
  const pod = {
    apiVersion: 'v1',
    kind: 'Pod',
    metadata: {
      name: name,
      namespace: WORKSPACE_NAMESPACE,
      labels: {
        app: 'workspace',
        employee: name,
        role: employee.role,
        workspaceId: workspaceId
      }
    },
    spec: {
      serviceAccountName: 'workspace-provisioner',
      containers: [{
        name: 'code-server',
        image: `${ECR_REGISTRY}/employee-workspace:latest`,
        imagePullPolicy: 'Always',
        ports: [{
          containerPort: 8080,
          name: 'http'
        }],
        env: [
          { name: 'EMPLOYEE_ID', value: employee.employeeId },
          { name: 'EMPLOYEE_EMAIL', value: employee.email },
          { name: 'EMPLOYEE_ROLE', value: employee.role },
          { 
            name: 'PASSWORD', 
            valueFrom: { 
              secretKeyRef: { 
                name: `${name}-secret`, 
                key: 'password' 
              } 
            } 
          }
        ],
        volumeMounts: [
          { name: 'workspace-storage', mountPath: '/home/coder/workspace' },
          { name: 'tmp', mountPath: '/tmp' }
        ],
        resources: {
          requests: { memory: '1Gi', cpu: '500m' },
          limits: { memory: '2Gi', cpu: '1000m' }
        },
        securityContext: {
          runAsNonRoot: true,
          runAsUser: 1000,
          allowPrivilegeEscalation: false,
          capabilities: { drop: ['ALL'] }
        }
      }],
      volumes: [
        { 
          name: 'workspace-storage', 
          persistentVolumeClaim: { claimName: `${name}-pvc` } 
        },
        { name: 'tmp', emptyDir: {} }
      ]
    }
  };

  await k8sApi.createNamespacedPod(WORKSPACE_NAMESPACE, pod);
}

async function createService(name) {
  const service = {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: name,
      namespace: WORKSPACE_NAMESPACE
    },
    spec: {
      selector: {
        employee: name
      },
      ports: [{
        protocol: 'TCP',
        port: 80,
        targetPort: 8080
      }],
      type: 'ClusterIP'
    }
  };

  await k8sApi.createNamespacedService(WORKSPACE_NAMESPACE, service);
}

async function createIngress(name) {
  const domain = process.env.WORKSPACE_DOMAIN || 'workspaces.innovatech.example.com';
  const host = `${name}.${domain}`;
  
  const ingress = {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'Ingress',
    metadata: {
      name: name,
      namespace: WORKSPACE_NAMESPACE,
      annotations: {
        'alb.ingress.kubernetes.io/scheme': 'internet-facing',
        'alb.ingress.kubernetes.io/target-type': 'ip',
        'alb.ingress.kubernetes.io/listen-ports': '[{"HTTPS":443}]',
        'alb.ingress.kubernetes.io/ssl-redirect': '443'
      }
    },
    spec: {
      ingressClassName: 'alb',
      rules: [{
        host: host,
        http: {
          paths: [{
            path: '/',
            pathType: 'Prefix',
            backend: {
              service: {
                name: name,
                port: { number: 80 }
              }
            }
          }]
        }
      }]
    }
  };

  await k8sNetworkingApi.createNamespacedIngress(WORKSPACE_NAMESPACE, ingress);
  return `https://${host}`;
}

async function cleanupWorkspace(name) {
  try {
    // Delete in reverse order
    await k8sNetworkingApi.deleteNamespacedIngress(name, WORKSPACE_NAMESPACE).catch(() => {});
    await k8sApi.deleteNamespacedService(name, WORKSPACE_NAMESPACE).catch(() => {});
    await k8sApi.deleteNamespacedPod(name, WORKSPACE_NAMESPACE).catch(() => {});
    await k8sApi.deleteNamespacedSecret(`${name}-secret`, WORKSPACE_NAMESPACE).catch(() => {});
    await k8sApi.deleteNamespacedPersistentVolumeClaim(`${name}-pvc`, WORKSPACE_NAMESPACE).catch(() => {});
  } catch (error) {
    logger.error(`Error cleaning up workspace ${name}:`, error);
  }
}

function generateSecurePassword() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
  let password = '';
  for (let i = 0; i < 16; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}

module.exports = {
  provisionWorkspace,
  deprovisionWorkspace,
  getWorkspaceStatus
};
