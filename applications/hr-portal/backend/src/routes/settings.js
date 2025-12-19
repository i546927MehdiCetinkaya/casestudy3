const express = require('express');
const router = express.Router();
const { requirePermission } = require('../middleware/rbac');
const logger = require('../utils/logger');

// In-memory GPO templates storage (in production, use DynamoDB or S3)
let gpoTemplates = {
  Infrastructure: {
    software: ['PuTTY', 'WinSCP', 'VirtualBox', 'Wireshark', 'Docker Desktop'],
    settings: {
      wallpaper: 'corporate_infrastructure.jpg',
      browserHomepage: 'https://portal.innovatech.local',
      disableUAC: false,
    },
    description: 'DevOps and Infrastructure tools',
  },
  Engineering: {
    software: ['Visual Studio Code', 'Git', 'Node.js', 'Python', 'Docker Desktop'],
    settings: {
      wallpaper: 'corporate_engineering.jpg',
      browserHomepage: 'https://github.com/innovatech',
      disableUAC: false,
    },
    description: 'Software development tools',
  },
  Sales: {
    software: ['Microsoft Office', 'Teams', 'Zoom', 'Salesforce Desktop'],
    settings: {
      wallpaper: 'corporate_sales.jpg',
      browserHomepage: 'https://crm.innovatech.local',
      disableUAC: false,
    },
    description: 'Sales and CRM tools',
  },
  Marketing: {
    software: ['Adobe Creative Cloud', 'Figma', 'Canva Desktop', 'Microsoft Office'],
    settings: {
      wallpaper: 'corporate_marketing.jpg',
      browserHomepage: 'https://creative.innovatech.local',
      disableUAC: false,
    },
    description: 'Creative and marketing tools',
  },
  HR: {
    software: ['Microsoft Office', 'Teams', 'Workday Desktop'],
    settings: {
      wallpaper: 'corporate_hr.jpg',
      browserHomepage: 'https://hr.innovatech.local',
      disableUAC: false,
    },
    description: 'HR management tools',
  },
  Finance: {
    software: ['Microsoft Office', 'QuickBooks', 'SAP GUI', 'Excel Add-ins'],
    settings: {
      wallpaper: 'corporate_finance.jpg',
      browserHomepage: 'https://finance.innovatech.local',
      disableUAC: false,
    },
    description: 'Financial software and tools',
  },
};

/**
 * GET /api/settings/gpo
 * Get all GPO templates
 * Permissions: HR-Admins, IT-Admins (employees:create OR monitoring:read)
 */
router.get('/gpo', requirePermission('monitoring', 'read'), async (req, res) => {
  try {
    logger.info('[Settings API] Fetching GPO templates', {
      user: req.user?.username,
      groups: req.user?.groups,
    });

    res.json({
      success: true,
      templates: gpoTemplates,
    });
  } catch (error) {
    logger.error('[Settings API] Error fetching GPO templates:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch GPO templates',
      error: error.message,
    });
  }
});

/**
 * POST /api/settings/gpo
 * Update GPO templates
 * Permissions: HR-Admins only (employees:create)
 */
router.post('/gpo', requirePermission('employees', 'create'), async (req, res) => {
  try {
    const { templates } = req.body;

    if (!templates || typeof templates !== 'object') {
      return res.status(400).json({
        success: false,
        message: 'Invalid templates format. Expected object with role keys.',
      });
    }

    logger.info('[Settings API] Updating GPO templates', {
      user: req.user?.username,
      groups: req.user?.groups,
      roles: Object.keys(templates),
    });

    // Validate template structure
    for (const [role, template] of Object.entries(templates)) {
      if (!template.software || !Array.isArray(template.software)) {
        return res.status(400).json({
          success: false,
          message: `Invalid software array for role: ${role}`,
        });
      }

      if (!template.settings || typeof template.settings !== 'object') {
        return res.status(400).json({
          success: false,
          message: `Invalid settings object for role: ${role}`,
        });
      }
    }

    // Update templates (in production, save to DynamoDB/S3)
    gpoTemplates = { ...gpoTemplates, ...templates };

    logger.info('[Settings API] GPO templates updated successfully', {
      user: req.user?.username,
      updatedRoles: Object.keys(templates),
    });

    res.json({
      success: true,
      message: 'GPO templates updated successfully',
      templates: gpoTemplates,
    });
  } catch (error) {
    logger.error('[Settings API] Error updating GPO templates:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update GPO templates',
      error: error.message,
    });
  }
});

/**
 * GET /api/settings/gpo/:role
 * Get GPO template for specific role
 * Permissions: Anyone authenticated
 */
router.get('/gpo/:role', async (req, res) => {
  try {
    const { role } = req.params;

    logger.info('[Settings API] Fetching GPO template for role', {
      role,
      user: req.user?.username,
    });

    const template = gpoTemplates[role];

    if (!template) {
      return res.status(404).json({
        success: false,
        message: `No GPO template found for role: ${role}`,
      });
    }

    res.json({
      success: true,
      role,
      template,
    });
  } catch (error) {
    logger.error('[Settings API] Error fetching GPO template:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch GPO template',
      error: error.message,
    });
  }
});

module.exports = router;
