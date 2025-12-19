import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Chip,
  IconButton,
  TextField,
  Button,
  Alert,
  Divider,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  CircularProgress,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Save as SaveIcon,
  Settings as SettingsIcon,
} from '@mui/icons-material';

// Default GPO templates per role/department
const DEFAULT_GPO_TEMPLATES = {
  'Infrastructure': {
    software: ['PuTTY', 'WinSCP', 'VirtualBox', 'Wireshark', 'Docker Desktop'],
    settings: {
      wallpaper: 'corporate-tech.jpg',
      browserHomepage: 'https://portal.innovatech.local',
      disableUAC: false,
    },
    description: 'DevOps, SysAdmin, Infrastructure roles'
  },
  'Engineering': {
    software: ['Visual Studio Code', 'Git', 'Node.js', 'Python', 'Docker Desktop'],
    settings: {
      wallpaper: 'corporate-dev.jpg',
      browserHomepage: 'https://github.com/innovatech',
      disableUAC: false,
    },
    description: 'Software Engineers, Developers'
  },
  'Sales': {
    software: ['Microsoft Office', 'Teams', 'Zoom', 'Salesforce Desktop'],
    settings: {
      wallpaper: 'corporate-sales.jpg',
      browserHomepage: 'https://crm.innovatech.local',
      disableUAC: true,
    },
    description: 'Sales Representatives, Account Managers'
  },
  'Marketing': {
    software: ['Adobe Creative Cloud', 'Figma', 'Canva Desktop', 'Microsoft Office'],
    settings: {
      wallpaper: 'corporate-marketing.jpg',
      browserHomepage: 'https://marketing.innovatech.local',
      disableUAC: true,
    },
    description: 'Marketing Team, Designers'
  },
  'HR': {
    software: ['Microsoft Office', 'Teams', 'Workday Desktop'],
    settings: {
      wallpaper: 'corporate-hr.jpg',
      browserHomepage: 'https://hr-portal.innovatech.local',
      disableUAC: true,
    },
    description: 'Human Resources, Recruiters'
  },
  'Finance': {
    software: ['Microsoft Office', 'QuickBooks', 'SAP GUI', 'Excel Add-ins'],
    settings: {
      wallpaper: 'corporate-finance.jpg',
      browserHomepage: 'https://finance.innovatech.local',
      disableUAC: false,
    },
    description: 'Finance Team, Accountants'
  },
};

function Settings() {
  const [gpoTemplates, setGpoTemplates] = useState(DEFAULT_GPO_TEMPLATES);
  const [selectedRole, setSelectedRole] = useState('Infrastructure');
  const [newSoftware, setNewSoftware] = useState('');
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Fetch GPO templates on mount
  useEffect(() => {
    fetchGPOTemplates();
  }, []);

  const fetchGPOTemplates = async () => {
    try {
      setLoading(true);
      const response = await fetch('/api/settings/gpo', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
        },
      });

      if (!response.ok) {
        throw new Error('Failed to fetch GPO templates');
      }

      const data = await response.json();
      if (data.success && data.templates) {
        setGpoTemplates(data.templates);
      }
    } catch (err) {
      console.error('[Settings] Error fetching GPO templates:', err);
      setError('Failed to load GPO templates. Using defaults.');
      setTimeout(() => setError(null), 5000);
    } finally {
      setLoading(false);
    }
  };

  const handleAddSoftware = () => {
    if (!newSoftware.trim()) return;

    setGpoTemplates(prev => ({
      ...prev,
      [selectedRole]: {
        ...prev[selectedRole],
        software: [...prev[selectedRole].software, newSoftware.trim()]
      }
    }));

    setNewSoftware('');
  };

  const handleRemoveSoftware = (roleKey, softwareIndex) => {
    setGpoTemplates(prev => ({
      ...prev,
      [roleKey]: {
        ...prev[roleKey],
        software: prev[roleKey].software.filter((_, i) => i !== softwareIndex)
      }
    }));
  };

  const handleSaveGPO = async () => {
    try {
      setLoading(true);
      setError(null);

      const response = await fetch('/api/settings/gpo', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
        },
        body: JSON.stringify({ templates: gpoTemplates }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || 'Failed to save GPO templates');
      }

      console.log('[Settings] GPO templates saved successfully');
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);

      // Refresh templates from server
      if (data.templates) {
        setGpoTemplates(data.templates);
      }
    } catch (err) {
      console.error('[Settings] Error saving GPO templates:', err);
      setError(err.message || 'Failed to save GPO templates');
      setTimeout(() => setError(null), 5000);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
        <SettingsIcon sx={{ fontSize: 32, color: 'primary.main' }} />
        <Typography variant="h4" sx={{ fontWeight: 700 }}>
          Workspace GPO Settings
        </Typography>
      </Box>

      {saveSuccess && (
        <Alert severity="success" sx={{ mb: 3 }}>
          GPO templates saved successfully! These will be applied to new workspaces.
        </Alert>
      )}

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {loading && (
        <Box sx={{ display: 'flex', justifyContent: 'center', my: 3 }}>
          <CircularProgress />
        </Box>
      )}

      <Alert severity="info" sx={{ mb: 3 }}>
        <Typography variant="body2">
          <strong>Group Policy Objects (GPO)</strong> automatically configure software and settings based on employee role.
          When a workspace is provisioned, the appropriate GPO template is applied.
        </Typography>
      </Alert>

      <Grid container spacing={3}>
        {/* Role Templates Overview */}
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ fontWeight: 600 }}>
                Role Templates
              </Typography>
              <Divider sx={{ mb: 2 }} />
              <List>
                {Object.keys(gpoTemplates).map((roleKey) => (
                  <ListItem
                    key={roleKey}
                    button
                    selected={selectedRole === roleKey}
                    onClick={() => setSelectedRole(roleKey)}
                    sx={{
                      borderRadius: 1,
                      mb: 1,
                      backgroundColor: selectedRole === roleKey ? 'primary.main' : 'transparent'
                    }}
                  >
                    <ListItemText
                      primary={roleKey}
                      secondary={`${gpoTemplates[roleKey].software.length} software packages`}
                      primaryTypographyProps={{ fontWeight: 600 }}
                    />
                  </ListItem>
                ))}
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* Selected Role Configuration */}
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  {selectedRole} GPO Template
                </Typography>
                <Chip
                  label={gpoTemplates[selectedRole].description}
                  color="primary"
                  variant="outlined"
                />
              </Box>
              <Divider sx={{ mb: 3 }} />

              {/* Software Packages */}
              <Typography variant="subtitle1" gutterBottom sx={{ fontWeight: 600, mt: 2 }}>
                📦 Auto-Install Software
              </Typography>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                These applications will be automatically installed when a workspace is provisioned for this role.
              </Typography>

              <Box sx={{ display: 'flex', gap: 1, mb: 2, flexWrap: 'wrap', mt: 2 }}>
                {gpoTemplates[selectedRole].software.map((software, index) => (
                  <Chip
                    key={index}
                    label={software}
                    onDelete={() => handleRemoveSoftware(selectedRole, index)}
                    color="primary"
                    deleteIcon={<DeleteIcon />}
                  />
                ))}
              </Box>

              <Box sx={{ display: 'flex', gap: 1, mb: 3 }}>
                <TextField
                  size="small"
                  placeholder="Add software (e.g., Docker Desktop)"
                  value={newSoftware}
                  onChange={(e) => setNewSoftware(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleAddSoftware()}
                  fullWidth
                />
                <Button
                  variant="contained"
                  startIcon={<AddIcon />}
                  onClick={handleAddSoftware}
                >
                  Add
                </Button>
              </Box>

              {/* System Settings */}
              <Typography variant="subtitle1" gutterBottom sx={{ fontWeight: 600, mt: 3 }}>
                ⚙️ System Settings
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={12} md={6}>
                  <TextField
                    fullWidth
                    size="small"
                    label="Desktop Wallpaper"
                    value={gpoTemplates[selectedRole].settings.wallpaper}
                    onChange={(e) => setGpoTemplates(prev => ({
                      ...prev,
                      [selectedRole]: {
                        ...prev[selectedRole],
                        settings: {
                          ...prev[selectedRole].settings,
                          wallpaper: e.target.value
                        }
                      }
                    }))}
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <TextField
                    fullWidth
                    size="small"
                    label="Browser Homepage"
                    value={gpoTemplates[selectedRole].settings.browserHomepage}
                    onChange={(e) => setGpoTemplates(prev => ({
                      ...prev,
                      [selectedRole]: {
                        ...prev[selectedRole],
                        settings: {
                          ...prev[selectedRole].settings,
                          browserHomepage: e.target.value
                        }
                      }
                    }))}
                  />
                </Grid>
              </Grid>

              <Box sx={{ mt: 4, display: 'flex', justifyContent: 'flex-end' }}>
                <Button
                  variant="contained"
                  size="large"
                  startIcon={<SaveIcon />}
                  onClick={handleSaveGPO}
                  sx={{
                    background: 'linear-gradient(135deg, var(--accent-primary), var(--accent-secondary))',
                    boxShadow: '0 4px 12px rgba(99, 102, 241, 0.4)'
                  }}
                >
                  Save GPO Templates
                </Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}

export default Settings;
