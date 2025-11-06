const express = require('express');
const workspaceService = require('../services/workspace');
const dynamodbService = require('../services/dynamodb');

const router = express.Router();

// Get all workspaces
router.get('/', async (req, res, next) => {
  try {
    const workspaces = await dynamodbService.getAllWorkspaces();
    res.json({ workspaces });
  } catch (error) {
    next(error);
  }
});

// Get workspace by employee ID
router.get('/employee/:employeeId', async (req, res, next) => {
  try {
    const workspace = await dynamodbService.getWorkspaceByEmployee(req.params.employeeId);
    if (!workspace) {
      return res.status(404).json({ error: 'Workspace not found' });
    }
    res.json({ workspace });
  } catch (error) {
    next(error);
  }
});

// Get workspace status
router.get('/:workspaceId/status', async (req, res, next) => {
  try {
    const status = await workspaceService.getWorkspaceStatus(req.params.workspaceId);
    res.json({ status });
  } catch (error) {
    next(error);
  }
});

// Manually provision workspace
router.post('/provision/:employeeId', async (req, res, next) => {
  try {
    const employee = await dynamodbService.getEmployee(req.params.employeeId);
    if (!employee) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    const workspace = await workspaceService.provisionWorkspace(employee);
    res.status(201).json({ workspace });
  } catch (error) {
    next(error);
  }
});

// Manually deprovision workspace
router.delete('/:employeeId', async (req, res, next) => {
  try {
    await workspaceService.deprovisionWorkspace(req.params.employeeId);
    res.json({ message: 'Workspace deprovisioned successfully' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
