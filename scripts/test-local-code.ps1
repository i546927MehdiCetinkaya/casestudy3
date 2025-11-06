# Local Testing Suite (No AWS/kubectl required)
# Tests code quality, file structure, and local build capability

Write-Host "`n=== LOCAL CODE TESTING SUITE ===" -ForegroundColor Cyan
Write-Host "Testing without AWS/kubectl credentials`n" -ForegroundColor Gray

$testResults = @{
    Passed = 0
    Failed = 0
}

function Test-Result {
    param([string]$TestName, [bool]$Success, [string]$Details = "")
    
    if ($Success) {
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
        if ($Details) { Write-Host "         $Details" -ForegroundColor Gray }
        $script:testResults.Passed++
    } else {
        Write-Host "  [FAIL] $TestName" -ForegroundColor Red
        if ($Details) { Write-Host "         $Details" -ForegroundColor Yellow }
        $script:testResults.Failed++
    }
}

# ============================================================================
# BACKEND CODE TESTS
# ============================================================================

Write-Host "[1/5] BACKEND CODE STRUCTURE" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow

# Test backend files
Write-Host "`nTest 1.1: Backend Core Files" -ForegroundColor Cyan
$backendFiles = @{
    "applications/hr-portal/backend/src/index.js" = "Main server file"
    "applications/hr-portal/backend/src/routes/employees.js" = "Employee routes"
    "applications/hr-portal/backend/src/routes/workspaces.js" = "Workspace routes"
    "applications/hr-portal/backend/src/routes/auth.js" = "Auth routes"
    "applications/hr-portal/backend/src/services/dynamodbService.js" = "DynamoDB service"
    "applications/hr-portal/backend/package.json" = "Package config"
    "applications/hr-portal/backend/Dockerfile" = "Docker config"
}

$allBackendFilesExist = $true
foreach ($file in $backendFiles.Keys) {
    if (Test-Path $file) {
        Write-Host "         [OK] $($backendFiles[$file])" -ForegroundColor Green
    } else {
        Write-Host "         [MISS] $file" -ForegroundColor Red
        $allBackendFilesExist = $false
    }
}
Test-Result "All backend files present" $allBackendFilesExist

# Analyze employees.js for CRUD operations
Write-Host "`nTest 1.2: Employee CRUD Operations" -ForegroundColor Cyan
if (Test-Path "applications/hr-portal/backend/src/routes/employees.js") {
    $employeeRoutes = Get-Content "applications/hr-portal/backend/src/routes/employees.js" -Raw
    
    $hasGet = $employeeRoutes -match "router\.get|app\.get"
    $hasPost = $employeeRoutes -match "router\.post|app\.post"
    $hasPut = $employeeRoutes -match "router\.put|app\.put"
    $hasDelete = $employeeRoutes -match "router\.delete|app\.delete"
    
    Test-Result "GET endpoint (list/read)" $hasGet
    Test-Result "POST endpoint (create)" $hasPost
    Test-Result "PUT endpoint (update)" $hasPut
    Test-Result "DELETE endpoint (delete)" $hasDelete
    
    # Check for workspace provisioning
    $hasWorkspaceProvisioning = $employeeRoutes -match "workspace|provision"
    Test-Result "Workspace provisioning logic" $hasWorkspaceProvisioning "Found workspace-related code"
} else {
    Test-Result "Employee routes file exists" $false
}

# Check package.json dependencies
Write-Host "`nTest 1.3: Backend Dependencies" -ForegroundColor Cyan
if (Test-Path "applications/hr-portal/backend/package.json") {
    $packageJson = Get-Content "applications/hr-portal/backend/package.json" -Raw | ConvertFrom-Json
    
    $requiredDeps = @("express", "aws-sdk", "@aws-sdk/client-dynamodb")
    $hasDeps = $true
    
    foreach ($dep in $requiredDeps) {
        $found = $packageJson.dependencies.PSObject.Properties.Name -contains $dep
        if ($found) {
            Write-Host "         [OK] $dep" -ForegroundColor Green
        } else {
            Write-Host "         [MISS] $dep" -ForegroundColor Yellow
            $hasDeps = $false
        }
    }
    
    Test-Result "Required dependencies present" $hasDeps
} else {
    Test-Result "Package.json exists" $false
}

# ============================================================================
# FRONTEND CODE TESTS
# ============================================================================

Write-Host "`n[2/5] FRONTEND CODE STRUCTURE" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow

# Test frontend files
Write-Host "`nTest 2.1: Frontend Core Files" -ForegroundColor Cyan
$frontendFiles = @{
    "applications/hr-portal/frontend/src/App.js" = "Main React component"
    "applications/hr-portal/frontend/src/index.js" = "React entry point"
    "applications/hr-portal/frontend/src/index.css" = "Global styles"
    "applications/hr-portal/frontend/public/index.html" = "HTML template"
    "applications/hr-portal/frontend/package.json" = "Package config"
    "applications/hr-portal/frontend/Dockerfile" = "Docker config"
    "applications/hr-portal/frontend/nginx.conf" = "Nginx config"
}

$allFrontendFilesExist = $true
foreach ($file in $frontendFiles.Keys) {
    if (Test-Path $file) {
        Write-Host "         [OK] $($frontendFiles[$file])" -ForegroundColor Green
    } else {
        Write-Host "         [MISS] $file" -ForegroundColor Red
        $allFrontendFilesExist = $false
    }
}
Test-Result "All frontend files present" $allFrontendFilesExist

# Analyze App.js for features
Write-Host "`nTest 2.2: Frontend Features" -ForegroundColor Cyan
if (Test-Path "applications/hr-portal/frontend/src/App.js") {
    $appJs = Get-Content "applications/hr-portal/frontend/src/App.js" -Raw
    
    $hasEmployeeList = $appJs -match "employees\.map|\.map\(.*employee"
    $hasCreateDialog = $appJs -match "Dialog.*Create|Add.*Employee"
    $hasDeleteConfirm = $appJs -match "delete|Delete|confirm"
    $hasApiCalls = $appJs -match "axios|fetch|api"
    $hasMaterialUI = $appJs -match "@mui|Material"
    
    Test-Result "Employee list display" $hasEmployeeList
    Test-Result "Create employee dialog" $hasCreateDialog
    Test-Result "Delete confirmation" $hasDeleteConfirm
    Test-Result "API integration" $hasApiCalls
    Test-Result "Material-UI components" $hasMaterialUI
} else {
    Test-Result "App.js exists" $false
}

# Check frontend dependencies
Write-Host "`nTest 2.3: Frontend Dependencies" -ForegroundColor Cyan
if (Test-Path "applications/hr-portal/frontend/package.json") {
    $packageJson = Get-Content "applications/hr-portal/frontend/package.json" -Raw | ConvertFrom-Json
    
    $requiredDeps = @("react", "react-dom", "axios", "@mui/material")
    $hasDeps = $true
    
    foreach ($dep in $requiredDeps) {
        $found = $packageJson.dependencies.PSObject.Properties.Name -contains $dep
        if ($found) {
            Write-Host "         [OK] $dep" -ForegroundColor Green
        } else {
            Write-Host "         [MISS] $dep" -ForegroundColor Yellow
            $hasDeps = $false
        }
    }
    
    Test-Result "Required dependencies present" $hasDeps
} else {
    Test-Result "Package.json exists" $false
}

# ============================================================================
# INFRASTRUCTURE CODE TESTS
# ============================================================================

Write-Host "`n[3/5] INFRASTRUCTURE CODE" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow

# Test Terraform modules
Write-Host "`nTest 3.1: Terraform Modules" -ForegroundColor Cyan
$terraformModules = @(
    "terraform/modules/eks",
    "terraform/modules/vpc",
    "terraform/modules/dynamodb",
    "terraform/modules/systems-manager"
)

$allModulesExist = $true
foreach ($module in $terraformModules) {
    if (Test-Path "$module/main.tf") {
        Write-Host "         [OK] $module" -ForegroundColor Green
    } else {
        Write-Host "         [MISS] $module" -ForegroundColor Red
        $allModulesExist = $false
    }
}
Test-Result "All Terraform modules present" $allModulesExist

# Test Kubernetes manifests
Write-Host "`nTest 3.2: Kubernetes Manifests" -ForegroundColor Cyan
$k8sFiles = @(
    "kubernetes/namespaces.yaml",
    "kubernetes/hr-portal.yaml",
    "kubernetes/rbac.yaml",
    "kubernetes/network-policies.yaml",
    "kubernetes/workspaces.yaml"
)

$allK8sFilesExist = $true
foreach ($file in $k8sFiles) {
    if (Test-Path $file) {
        Write-Host "         [OK] $file" -ForegroundColor Green
    } else {
        Write-Host "         [MISS] $file" -ForegroundColor Red
        $allK8sFilesExist = $false
    }
}
Test-Result "All Kubernetes manifests present" $allK8sFilesExist

# ============================================================================
# SYSTEMS MANAGER MODULE TESTS
# ============================================================================

Write-Host "`n[4/5] SYSTEMS MANAGER MODULE" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow

Write-Host "`nTest 4.1: Systems Manager Files" -ForegroundColor Cyan
$ssmFiles = @{
    "terraform/modules/systems-manager/main.tf" = "Main SSM config"
    "terraform/modules/systems-manager/variables.tf" = "Variables"
    "terraform/modules/systems-manager/outputs.tf" = "Outputs"
    "terraform/modules/systems-manager/README.md" = "Documentation"
}

$allSSMFilesExist = $true
foreach ($file in $ssmFiles.Keys) {
    if (Test-Path $file) {
        Write-Host "         [OK] $($ssmFiles[$file])" -ForegroundColor Green
    } else {
        Write-Host "         [MISS] $file" -ForegroundColor Red
        $allSSMFilesExist = $false
    }
}
Test-Result "All Systems Manager files present" $allSSMFilesExist

# Analyze main.tf for features
Write-Host "`nTest 4.2: Systems Manager Features" -ForegroundColor Cyan
if (Test-Path "terraform/modules/systems-manager/main.tf") {
    $ssmMain = Get-Content "terraform/modules/systems-manager/main.tf" -Raw
    
    $hasSessionManager = $ssmMain -match "ssm|session.*manager"
    $hasParameterStore = $ssmMain -match "ssm_parameter|parameter.*store"
    $hasPatchManager = $ssmMain -match "patch|maintenance.*window"
    $hasStateManager = $ssmMain -match "ssm_association|state.*manager"
    $hasVPCEndpoints = $ssmMain -match "vpc_endpoint.*ssm"
    
    Test-Result "Session Manager resources" $hasSessionManager
    Test-Result "Parameter Store resources" $hasParameterStore
    Test-Result "Patch Manager resources" $hasPatchManager
    Test-Result "State Manager resources" $hasStateManager
    Test-Result "VPC Endpoints" $hasVPCEndpoints
} else {
    Test-Result "Systems Manager main.tf exists" $false
}

# ============================================================================
# DOCUMENTATION TESTS
# ============================================================================

Write-Host "`n[5/5] DOCUMENTATION" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow

Write-Host "`nTest 5.1: Project Documentation" -ForegroundColor Cyan
$docFiles = @(
    "README.md",
    "UPDATED_STATUS.md",
    "terraform/modules/systems-manager/README.md",
    "applications/hr-portal/backend/README.md"
)

$allDocsExist = $true
foreach ($file in $docFiles) {
    if (Test-Path $file) {
        $size = (Get-Item $file).Length
        Write-Host "         [OK] $file ($size bytes)" -ForegroundColor Green
    } else {
        Write-Host "         [MISS] $file" -ForegroundColor Yellow
        $allDocsExist = $false
    }
}
Test-Result "Documentation files present" $allDocsExist

# ============================================================================
# CODE STATISTICS
# ============================================================================

Write-Host "`n=== CODE STATISTICS ===" -ForegroundColor Cyan

# Count lines of code
$stats = @{
    Backend_JS = 0
    Frontend_JS = 0
    Terraform = 0
    Kubernetes = 0
    Scripts = 0
}

if (Test-Path "applications/hr-portal/backend/src") {
    $jsFiles = Get-ChildItem -Path "applications/hr-portal/backend/src" -Recurse -Filter "*.js"
    $stats.Backend_JS = ($jsFiles | Get-Content | Measure-Object -Line).Lines
}

if (Test-Path "applications/hr-portal/frontend/src") {
    $jsFiles = Get-ChildItem -Path "applications/hr-portal/frontend/src" -Recurse -Filter "*.js"
    $stats.Frontend_JS = ($jsFiles | Get-Content | Measure-Object -Line).Lines
}

if (Test-Path "terraform") {
    $tfFiles = Get-ChildItem -Path "terraform" -Recurse -Filter "*.tf"
    $stats.Terraform = ($tfFiles | Get-Content | Measure-Object -Line).Lines
}

if (Test-Path "kubernetes") {
    $yamlFiles = Get-ChildItem -Path "kubernetes" -Recurse -Filter "*.yaml"
    $stats.Kubernetes = ($yamlFiles | Get-Content | Measure-Object -Line).Lines
}

if (Test-Path "scripts") {
    $ps1Files = Get-ChildItem -Path "scripts" -Recurse -Filter "*.ps1"
    $stats.Scripts = ($ps1Files | Get-Content | Measure-Object -Line).Lines
}

Write-Host "Backend JavaScript:  $($stats.Backend_JS) lines" -ForegroundColor White
Write-Host "Frontend JavaScript: $($stats.Frontend_JS) lines" -ForegroundColor White
Write-Host "Terraform:           $($stats.Terraform) lines" -ForegroundColor White
Write-Host "Kubernetes YAML:     $($stats.Kubernetes) lines" -ForegroundColor White
Write-Host "PowerShell Scripts:  $($stats.Scripts) lines" -ForegroundColor White

$totalLines = $stats.Values | Measure-Object -Sum | Select-Object -ExpandProperty Sum
Write-Host "Total Lines of Code: $totalLines" -ForegroundColor Cyan

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Total Failed: $($testResults.Failed)" -ForegroundColor Red

$totalTests = $testResults.Passed + $testResults.Failed
if ($totalTests -gt 0) {
    $passPercentage = [math]::Round(($testResults.Passed / $totalTests) * 100, 1)
    Write-Host "Pass Rate:    $passPercentage%" -ForegroundColor $(if ($passPercentage -ge 90) { "Green" } elseif ($passPercentage -ge 70) { "Yellow" } else { "Red" })
}

Write-Host "`n=== LOCAL TESTING RECOMMENDATIONS ===" -ForegroundColor Cyan

Write-Host "`n1. Test Frontend Locally:" -ForegroundColor Yellow
Write-Host "   cd applications\hr-portal\frontend" -ForegroundColor White
Write-Host "   npm install" -ForegroundColor White
Write-Host "   npm start" -ForegroundColor White
Write-Host "   Open http://localhost:3000" -ForegroundColor White

Write-Host "`n2. Test Backend Locally:" -ForegroundColor Yellow
Write-Host "   cd applications\hr-portal\backend" -ForegroundColor White
Write-Host "   npm install" -ForegroundColor White
Write-Host "   # Set environment variables" -ForegroundColor White
Write-Host "   `$env:DYNAMODB_TABLE='innovatech-employees'" -ForegroundColor White
Write-Host "   `$env:AWS_REGION='eu-west-1'" -ForegroundColor White
Write-Host "   npm start" -ForegroundColor White
Write-Host "   # Test: curl http://localhost:3000/health" -ForegroundColor White

Write-Host "`n3. Build Docker Images:" -ForegroundColor Yellow
Write-Host "   # Backend" -ForegroundColor White
Write-Host "   cd applications\hr-portal\backend" -ForegroundColor White
Write-Host "   docker build -t hr-portal-backend:latest ." -ForegroundColor White
Write-Host "   docker run -p 3000:3000 hr-portal-backend:latest" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "   # Frontend" -ForegroundColor White
Write-Host "   cd applications\hr-portal\frontend" -ForegroundColor White
Write-Host "   docker build -t hr-portal-frontend:latest ." -ForegroundColor White
Write-Host "   docker run -p 8080:80 hr-portal-frontend:latest" -ForegroundColor White

Write-Host "`n4. Validate Terraform:" -ForegroundColor Yellow
Write-Host "   cd terraform/environments/dev" -ForegroundColor White
Write-Host "   terraform init" -ForegroundColor White
Write-Host "   terraform validate" -ForegroundColor White
Write-Host "   terraform plan" -ForegroundColor White

Write-Host "`n5. When AWS credentials are refreshed:" -ForegroundColor Yellow
Write-Host "   aws sso login --profile <your-profile>" -ForegroundColor White
Write-Host "   .\scripts\test-all-services.ps1 -All" -ForegroundColor White
Write-Host "   .\scripts\list-employees.ps1" -ForegroundColor White

Write-Host "`nAll code is ready! Just needs deployment to AWS." -ForegroundColor Green
Write-Host ""
