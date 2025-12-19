import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  IconButton,
  Tooltip,
  Paper,
} from '@mui/material';
import {
  Refresh as RefreshIcon,
  Fullscreen as FullscreenIcon,
  Timeline as TimelineIcon,
} from '@mui/icons-material';

const MonitoringDashboard = () => {
  const [timeRange, setTimeRange] = useState('3h');
  const [refreshKey, setRefreshKey] = useState(0);
  const [theme, setTheme] = useState('dark');

  // Grafana embed URL - custom DNS voor monitoring portal
  const grafanaBaseUrl = 'http://monitoring.innovatech.local:30300';
  const dashboardUid = 'ce28fec6-b401-425c-b9fb-02e20f8eae77'; // Dit is de UID van je dashboard
  
  const embedUrl = `${grafanaBaseUrl}/d-solo/${dashboardUid}/innovatech-platform-overview?orgId=1&theme=${theme}&from=now-${timeRange}&to=now&refresh=30s&panelId=`;

  const handleRefresh = () => {
    setRefreshKey(prev => prev + 1);
  };

  const handleFullscreen = () => {
    window.open(`${grafanaBaseUrl}/d/${dashboardUid}/innovatech-platform-overview?orgId=1&from=now-${timeRange}&to=now&refresh=30s`, '_blank');
  };

  // Panel configuraties - deze IDs komen uit je dashboard
  const panels = [
    { id: 1, title: 'Total Employees', height: 150 },
    { id: 2, title: 'Online Employees', height: 150 },
    { id: 3, title: 'Terminated/Failed', height: 150 },
    { id: 7, title: 'Employee Workspaces Over Time', height: 300, width: 12 },
    { id: 9, title: 'Employee List', height: 400, width: 12 },
    { id: 11, title: 'Pods by Namespace', height: 350, width: 6 },
    { id: 14, title: 'Cluster Node Status', height: 350, width: 6 },
  ];

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Paper
        elevation={2}
        sx={{
          p: 2,
          mb: 3,
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          color: 'white',
        }}
      >
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <TimelineIcon sx={{ fontSize: 40 }} />
            <Box>
              <Typography variant="h4" sx={{ fontWeight: 'bold', fontFamily: 'Inter, sans-serif' }}>
                Platform Monitoring
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.9 }}>
                Real-time employee workspace metrics
              </Typography>
            </Box>
          </Box>

          <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
            <FormControl size="small" sx={{ minWidth: 120, bgcolor: 'rgba(255,255,255,0.2)', borderRadius: 1 }}>
              <InputLabel sx={{ color: 'white' }}>Time Range</InputLabel>
              <Select
                value={timeRange}
                onChange={(e) => setTimeRange(e.target.value)}
                sx={{ color: 'white', '.MuiOutlinedInput-notchedOutline': { borderColor: 'rgba(255,255,255,0.3)' } }}
              >
                <MenuItem value="15m">Last 15 minutes</MenuItem>
                <MenuItem value="1h">Last 1 hour</MenuItem>
                <MenuItem value="3h">Last 3 hours</MenuItem>
                <MenuItem value="6h">Last 6 hours</MenuItem>
                <MenuItem value="24h">Last 24 hours</MenuItem>
              </Select>
            </FormControl>

            <Tooltip title="Refresh Dashboard">
              <IconButton onClick={handleRefresh} sx={{ color: 'white' }}>
                <RefreshIcon />
              </IconButton>
            </Tooltip>

            <Tooltip title="Open in Fullscreen">
              <IconButton onClick={handleFullscreen} sx={{ color: 'white' }}>
                <FullscreenIcon />
              </IconButton>
            </Tooltip>
          </Box>
        </Box>
      </Paper>

      {/* Dashboard Grid */}
      <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(12, 1fr)', gap: 2 }}>
        {/* Stats Row */}
        <Card sx={{ gridColumn: 'span 4', fontFamily: 'Inter, sans-serif' }}>
          <CardContent sx={{ p: 0, '&:last-child': { pb: 0 } }}>
            <iframe
              key={`panel-1-${refreshKey}`}
              src={`${embedUrl}1`}
              width="100%"
              height="150"
              frameBorder="0"
              style={{ border: 'none' }}
              title="Total Employees"
            />
          </CardContent>
        </Card>

        <Card sx={{ gridColumn: 'span 4', fontFamily: 'Inter, sans-serif' }}>
          <CardContent sx={{ p: 0, '&:last-child': { pb: 0 } }}>
            <iframe
              key={`panel-2-${refreshKey}`}
              src={`${embedUrl}2`}
              width="100%"
              height="150"
              frameBorder="0"
              style={{ border: 'none' }}
              title="Online Employees"
            />
          </CardContent>
        </Card>

        <Card sx={{ gridColumn: 'span 4', fontFamily: 'Inter, sans-serif' }}>
          <CardContent sx={{ p: 0, '&:last-child': { pb: 0 } }}>
            <iframe
              key={`panel-3-${refreshKey}`}
              src={`${embedUrl}3`}
              width="100%"
              height="150"
              frameBorder="0"
              style={{ border: 'none' }}
              title="Terminated/Failed"
            />
          </CardContent>
        </Card>

        {/* Workspace Timeline */}
        <Card sx={{ gridColumn: 'span 12', fontFamily: 'Inter, sans-serif' }}>
          <CardContent sx={{ p: 0, '&:last-child': { pb: 0 } }}>
            <iframe
              key={`panel-7-${refreshKey}`}
              src={`${embedUrl}7`}
              width="100%"
              height="300"
              frameBorder="0"
              style={{ border: 'none' }}
              title="Employee Workspaces Over Time"
            />
          </CardContent>
        </Card>

        {/* Employee List */}
        <Card sx={{ gridColumn: 'span 12', fontFamily: 'Inter, sans-serif' }}>
          <CardContent sx={{ p: 0, '&:last-child': { pb: 0 } }}>
            <iframe
              key={`panel-9-${refreshKey}`}
              src={`${embedUrl}9`}
              width="100%"
              height="400"
              frameBorder="0"
              style={{ border: 'none' }}
              title="Employee List"
            />
          </CardContent>
        </Card>

        {/* Pie Chart and Node Status */}
        <Card sx={{ gridColumn: 'span 6', fontFamily: 'Inter, sans-serif' }}>
          <CardContent sx={{ p: 0, '&:last-child': { pb: 0 } }}>
            <iframe
              key={`panel-11-${refreshKey}`}
              src={`${embedUrl}11`}
              width="100%"
              height="350"
              frameBorder="0"
              style={{ border: 'none' }}
              title="Pods by Namespace"
            />
          </CardContent>
        </Card>

        <Card sx={{ gridColumn: 'span 6', fontFamily: 'Inter, sans-serif' }}>
          <CardContent sx={{ p: 0, '&:last-child': { pb: 0 } }}>
            <iframe
              key={`panel-14-${refreshKey}`}
              src={`${embedUrl}14`}
              width="100%"
              height="350"
              frameBorder="0"
              style={{ border: 'none' }}
              title="Cluster Node Status"
            />
          </CardContent>
        </Card>
      </Box>

      {/* Info Footer */}
      <Paper
        elevation={1}
        sx={{
          mt: 3,
          p: 2,
          bgcolor: '#f5f5f5',
          borderLeft: '4px solid #667eea',
        }}
      >
        <Typography variant="body2" sx={{ fontFamily: 'Inter, sans-serif', color: '#666' }}>
          <strong>Live Updates:</strong> Dashboard refreshes automatically every 30 seconds. 
          Use the time range selector to view historical data.
        </Typography>
      </Paper>
    </Box>
  );
};

export default MonitoringDashboard;
