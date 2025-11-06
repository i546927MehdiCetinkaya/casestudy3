# Practical Demo: Test Frontend & Backend Locally
# This guide helps you test the employee lifecycle and workspace provisioning locally

Write-Host @"

╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║         FRONTEND & BACKEND LOCAL TESTING GUIDE                    ║
║                                                                   ║
║    Test employee creation and workspace provisioning locally     ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

Write-Host "=== WHAT WE'RE GOING TO TEST ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Backend API" -ForegroundColor White
Write-Host "   - Health check endpoint" -ForegroundColor Gray
Write-Host "   - Employee CRUD operations" -ForegroundColor Gray
Write-Host "   - Workspace provisioning logic" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Frontend UI" -ForegroundColor White
Write-Host "   - Material-UI interface" -ForegroundColor Gray
Write-Host "   - Employee list display" -ForegroundColor Gray
Write-Host "   - Create employee form" -ForegroundColor Gray
Write-Host "   - Delete confirmation" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Integration" -ForegroundColor White
Write-Host "   - Frontend calls Backend API" -ForegroundColor Gray
Write-Host "   - Employee data flow" -ForegroundColor Gray
Write-Host "   - Error handling" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Start testing? (y/n)"
if ($choice -ne 'y') {
    Write-Host "Exiting..." -ForegroundColor Yellow
    exit
}

# ============================================================================
# STEP 1: TEST BACKEND
# ============================================================================

Write-Host "`n=== STEP 1: TEST BACKEND API ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Checking backend files..." -ForegroundColor Yellow
if (-not (Test-Path "applications/hr-portal/backend")) {
    Write-Host "[ERROR] Backend directory not found!" -ForegroundColor Red
    exit 1
}

cd applications/hr-portal/backend

Write-Host "[1/4] Checking package.json..." -ForegroundColor White
if (Test-Path "package.json") {
    Write-Host "  [OK] package.json exists" -ForegroundColor Green
    
    # Check if node_modules exists
    if (-not (Test-Path "node_modules")) {
        Write-Host "  [INFO] Installing dependencies..." -ForegroundColor Yellow
        npm install
    } else {
        Write-Host "  [OK] node_modules exists" -ForegroundColor Green
    }
} else {
    Write-Host "  [ERROR] package.json not found!" -ForegroundColor Red
    exit 1
}

Write-Host "`n[2/4] Setting environment variables..." -ForegroundColor White
$env:DYNAMODB_TABLE = "innovatech-employees"
$env:DYNAMODB_WORKSPACES_TABLE = "innovatech-employees-workspaces"
$env:AWS_REGION = "eu-west-1"
$env:NODE_ENV = "development"
$env:PORT = "3000"
$env:JWT_SECRET = "local-dev-secret"

Write-Host "  [OK] Environment configured" -ForegroundColor Green
Write-Host "       TABLE: $env:DYNAMODB_TABLE" -ForegroundColor Gray
Write-Host "       REGION: $env:AWS_REGION" -ForegroundColor Gray
Write-Host "       PORT: $env:PORT" -ForegroundColor Gray

Write-Host "`n[3/4] Backend API Endpoints:" -ForegroundColor White
Write-Host "  GET  /health              - Health check" -ForegroundColor Gray
Write-Host "  GET  /ready               - Readiness check" -ForegroundColor Gray
Write-Host "  GET  /api/employees       - List all employees" -ForegroundColor Gray
Write-Host "  POST /api/employees       - Create employee" -ForegroundColor Gray
Write-Host "  GET  /api/employees/:id   - Get employee by ID" -ForegroundColor Gray
Write-Host "  PUT  /api/employees/:id   - Update employee" -ForegroundColor Gray
Write-Host "  DELETE /api/employees/:id - Delete employee" -ForegroundColor Gray

Write-Host "`n[4/4] Starting backend server..." -ForegroundColor White
Write-Host "  NOTE: Backend will attempt to connect to AWS DynamoDB" -ForegroundColor Yellow
Write-Host "  If AWS credentials are not configured, some endpoints will fail" -ForegroundColor Yellow
Write-Host "  But you can still see the API structure and routes!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C to stop the backend and continue to frontend testing" -ForegroundColor Cyan
Write-Host ""

# Start backend in background
$backendJob = Start-Job -ScriptBlock {
    param($BackendPath)
    cd $BackendPath
    npm start
} -ArgumentList (Get-Location).Path

Start-Sleep -Seconds 3

# Test health endpoint
Write-Host "Testing health endpoint..." -ForegroundColor White
try {
    $health = Invoke-RestMethod -Uri "http://localhost:3000/health" -Method Get -TimeoutSec 5
    Write-Host "  [OK] Backend is running!" -ForegroundColor Green
    Write-Host "       Response: $health" -ForegroundColor Gray
} catch {
    Write-Host "  [WARNING] Backend may not be running yet or port 3000 is busy" -ForegroundColor Yellow
    Write-Host "            You can start it manually: npm start" -ForegroundColor Gray
}

Write-Host "`nBackend is running in background (Job ID: $($backendJob.Id))" -ForegroundColor Cyan
Write-Host "To see logs: Receive-Job $($backendJob.Id)" -ForegroundColor Gray
Write-Host "To stop: Stop-Job $($backendJob.Id); Remove-Job $($backendJob.Id)" -ForegroundColor Gray

# ============================================================================
# STEP 2: TEST FRONTEND
# ============================================================================

Write-Host "`n=== STEP 2: TEST FRONTEND UI ===" -ForegroundColor Cyan
Write-Host ""

$frontendChoice = Read-Host "Start frontend testing? (y/n)"
if ($frontendChoice -ne 'y') {
    Write-Host "Skipping frontend..." -ForegroundColor Yellow
    Stop-Job $backendJob
    Remove-Job $backendJob
    cd ../../..
    exit
}

cd ../frontend

Write-Host "[1/4] Checking frontend files..." -ForegroundColor White
if (Test-Path "package.json") {
    Write-Host "  [OK] package.json exists" -ForegroundColor Green
    
    if (-not (Test-Path "node_modules")) {
        Write-Host "  [INFO] Installing dependencies..." -ForegroundColor Yellow
        Write-Host "        This may take a few minutes..." -ForegroundColor Gray
        npm install
    } else {
        Write-Host "  [OK] node_modules exists" -ForegroundColor Green
    }
} else {
    Write-Host "  [ERROR] package.json not found!" -ForegroundColor Red
    Stop-Job $backendJob
    Remove-Job $backendJob
    exit 1
}

Write-Host "`n[2/4] Setting frontend environment..." -ForegroundColor White
$env:REACT_APP_API_URL = "http://localhost:3000"
Write-Host "  [OK] API URL: $env:REACT_APP_API_URL" -ForegroundColor Green

Write-Host "`n[3/4] Frontend Features:" -ForegroundColor White
Write-Host "  - Material-UI design" -ForegroundColor Gray
Write-Host "  - Employee list with cards" -ForegroundColor Gray
Write-Host "  - Create employee dialog" -ForegroundColor Gray
Write-Host "  - Delete confirmation" -ForegroundColor Gray
Write-Host "  - Real-time API calls" -ForegroundColor Gray
Write-Host "  - Responsive layout" -ForegroundColor Gray

Write-Host "`n[4/4] Starting frontend dev server..." -ForegroundColor White
Write-Host "  Frontend will open at: http://localhost:3000" -ForegroundColor Cyan
Write-Host "  (Note: Backend is on port 3000, frontend dev server will use a different port)" -ForegroundColor Gray
Write-Host ""

# Create .env file for React
$envContent = "REACT_APP_API_URL=http://localhost:3000"
$envContent | Out-File -FilePath ".env" -Encoding UTF8

Write-Host "Starting frontend (this will open a browser)..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C when done testing" -ForegroundColor Cyan
Write-Host ""

npm start

# Cleanup
Write-Host "`nCleaning up..." -ForegroundColor Yellow
Stop-Job $backendJob
Remove-Job $backendJob
cd ../../..

Write-Host "[OK] Testing complete!" -ForegroundColor Green
Write-Host ""
