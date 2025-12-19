// Error Boundary - Catches React errors and shows fallback UI
// Prevents entire app crash on component errors

import React from 'react';
import { Box, Typography, Button, Paper } from '@mui/material';
import ErrorOutlineIcon from '@mui/icons-material/ErrorOutline';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
      errorInfo: null
    };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true };
  }

  componentDidCatch(error, errorInfo) {
    console.error('[ErrorBoundary] Caught error:', error, errorInfo);
    this.setState({
      error,
      errorInfo
    });
  }

  handleReset = () => {
    this.setState({
      hasError: false,
      error: null,
      errorInfo: null
    });
  };

  render() {
    if (this.state.hasError) {
      return (
        <Box
          display="flex"
          justifyContent="center"
          alignItems="center"
          minHeight="100vh"
          bgcolor="#1a1a1a"
          p={3}
        >
          <Paper
            elevation={3}
            sx={{
              p: 4,
              maxWidth: 600,
              bgcolor: '#2d2d2d',
              color: '#fff'
            }}
          >
            <Box display="flex" alignItems="center" mb={2}>
              <ErrorOutlineIcon sx={{ fontSize: 48, color: '#f44336', mr: 2 }} />
              <Typography variant="h4" component="h1">
                Oops! Something went wrong
              </Typography>
            </Box>

            <Typography variant="body1" paragraph sx={{ color: '#aaa' }}>
              We encountered an unexpected error. Don't worry, your data is safe.
              You can try refreshing the page or going back to the previous page.
            </Typography>

            {process.env.NODE_ENV === 'development' && this.state.error && (
              <Box
                mt={3}
                p={2}
                bgcolor="#1a1a1a"
                borderRadius={1}
                sx={{ fontFamily: 'monospace', fontSize: 12, overflow: 'auto' }}
              >
                <Typography variant="body2" sx={{ color: '#f44336', mb: 1 }}>
                  <strong>Error:</strong> {this.state.error.toString()}
                </Typography>
                {this.state.errorInfo && (
                  <Typography variant="body2" sx={{ color: '#888', whiteSpace: 'pre-wrap' }}>
                    {this.state.errorInfo.componentStack}
                  </Typography>
                )}
              </Box>
            )}

            <Box display="flex" gap={2} mt={4}>
              <Button
                variant="contained"
                onClick={() => window.location.reload()}
                sx={{
                  bgcolor: '#2196f3',
                  '&:hover': { bgcolor: '#1976d2' }
                }}
              >
                Refresh Page
              </Button>
              <Button
                variant="outlined"
                onClick={() => window.history.back()}
                sx={{
                  borderColor: '#555',
                  color: '#fff',
                  '&:hover': { borderColor: '#888' }
                }}
              >
                Go Back
              </Button>
              {this.props.resetable && (
                <Button
                  variant="outlined"
                  onClick={this.handleReset}
                  sx={{
                    borderColor: '#555',
                    color: '#fff',
                    '&:hover': { borderColor: '#888' }
                  }}
                >
                  Try Again
                </Button>
              )}
            </Box>
          </Paper>
        </Box>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
