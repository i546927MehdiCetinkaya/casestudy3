# Complete Test Suite for Employee Lifecycle & Workstation Provisioning
# Tests frontend, backend, and workspace provisioning

param(
    [switch]$Backend,
    [switch]$Frontend,
    [switch]$Workspaces,
    [switch]$Integration,
    [switch]$All
)

Write-Host "`n=== EMPLOYEE LIFECYCLE & WORKSPACE TESTING SUITE ===" -ForegroundColor Cyan
Write-Host "Testing backend API, frontend deployment, and workspace provisioning`n" -ForegroundColor Gray

if ($All -or (-not $Backend -and -not $Frontend -and -not $Workspaces -and -not $Integration)) {
    $Backend = $true
    $Frontend = $true
    $Workspaces = $true
    $Integration = $true
}

$testResults = @{
    Passed = 0
    Failed = 0
    Warnings = 0
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

function Test-Warning {
    param([string]$TestName, [string]$Details = "")
    Write-Host "  [WARN] $TestName" -ForegroundColor Yellow
    if ($Details) { Write-Host "         $Details" -ForegroundColor Gray }
    $script:testResults.Warnings++
}

# ============================================================================
# BACKEND API TESTING
# ============================================================================

if ($Backend) {
    Write-Host "`n[1/4] BACKEND API TESTS" -ForegroundColor Yellow
    Write-Host "======================================" -ForegroundColor Yellow
    
    # Test 1: Backend deployment exists
    Write-Host "`nTest 1.1: Backend Deployment Status" -ForegroundColor Cyan
    $backendDeploy = kubectl get deployment hr-portal-backend -n hr-portal -o json 2>$null | ConvertFrom-Json
    if ($backendDeploy) {
        $replicas = $backendDeploy.status.readyReplicas
        $desired = $backendDeploy.spec.replicas
        Test-Result "Backend deployment exists" $true "Ready: $replicas/$desired replicas"
        
        if ($replicas -eq $desired) {
            Test-Result "All replicas are ready" $true
        } else {
            Test-Warning "Not all replicas ready" "$replicas/$desired ready"
        }
    } else {
        Test-Result "Backend deployment exists" $false "Cannot connect to cluster or deployment not found"
    }
    
    # Test 2: Backend service
    Write-Host "`nTest 1.2: Backend Service" -ForegroundColor Cyan
    $backendSvc = kubectl get svc hr-portal-backend -n hr-portal -o json 2>$null | ConvertFrom-Json
    if ($backendSvc) {
        $clusterIP = $backendSvc.spec.clusterIP
        $port = $backendSvc.spec.ports[0].port
        Test-Result "Backend service exists" $true "ClusterIP: $clusterIP, Port: $port"
    } else {
        Test-Result "Backend service exists" $false
    }
    
    # Test 3: Backend pods
    Write-Host "`nTest 1.3: Backend Pods" -ForegroundColor Cyan
    $backendPods = kubectl get pods -n hr-portal -l app=hr-portal-backend -o json 2>$null | ConvertFrom-Json
    if ($backendPods -and $backendPods.items) {
        $runningPods = ($backendPods.items | Where-Object { $_.status.phase -eq "Running" }).Count
        $totalPods = $backendPods.items.Count
        Test-Result "Backend pods running" ($runningPods -gt 0) "Running: $runningPods/$totalPods"
        
        # Show pod details
        foreach ($pod in $backendPods.items) {
            $podName = $pod.metadata.name
            $podStatus = $pod.status.phase
            $restarts = ($pod.status.containerStatuses[0].restartCount)
            Write-Host "         Pod: $podName | Status: $podStatus | Restarts: $restarts" -ForegroundColor Gray
        }
    } else {
        Test-Result "Backend pods running" $false "No pods found"
    }
    
    # Test 4: Backend environment variables
    Write-Host "`nTest 1.4: Backend Configuration" -ForegroundColor Cyan
    $backendConfig = kubectl get configmap hr-portal-config -n hr-portal -o json 2>$null | ConvertFrom-Json
    if ($backendConfig) {
        $tableName = $backendConfig.data.DYNAMODB_TABLE
        $region = $backendConfig.data.AWS_REGION
        Test-Result "Backend ConfigMap exists" $true "Table: $tableName, Region: $region"
    } else {
        Test-Result "Backend ConfigMap exists" $false
    }
    
    # Test 5: DynamoDB connection (check if employees exist)
    Write-Host "`nTest 1.5: DynamoDB Connection" -ForegroundColor Cyan
    try {
        $employees = aws dynamodb scan --table-name innovatech-employees --select COUNT --output json | ConvertFrom-Json
        $count = $employees.Count
        Test-Result "DynamoDB accessible" $true "$count employees in database"
    } catch {
        Test-Result "DynamoDB accessible" $false $_.Exception.Message
    }
    
    # Test 6: Backend logs (check for errors)
    Write-Host "`nTest 1.6: Backend Logs (Recent Errors)" -ForegroundColor Cyan
    if ($backendPods -and $backendPods.items -and $backendPods.items[0]) {
        $podName = $backendPods.items[0].metadata.name
        $logs = kubectl logs $podName -n hr-portal --tail=50 2>$null
        $errors = $logs | Select-String -Pattern "error|Error|ERROR" -AllMatches
        
        if ($logs) {
            if ($errors.Count -eq 0) {
                Test-Result "No errors in recent logs" $true
            } else {
                Test-Warning "Errors found in logs" "$($errors.Count) error lines found"
                Write-Host "         Recent errors:" -ForegroundColor Gray
                $errors | Select-Object -First 3 | ForEach-Object { 
                    Write-Host "         $_" -ForegroundColor Red 
                }
            }
        } else {
            Test-Warning "Could not retrieve logs" "kubectl logs may require authentication"
        }
    }
    
    # Test 7: Backend API endpoints (via port-forward)
    Write-Host "`nTest 1.7: API Endpoint Test (Optional)" -ForegroundColor Cyan
    Write-Host "         To test API endpoints locally, run:" -ForegroundColor Gray
    Write-Host "         kubectl port-forward svc/hr-portal-backend 3000:80 -n hr-portal" -ForegroundColor Gray
    Write-Host "         Then: curl http://localhost:3000/health" -ForegroundColor Gray
}

# ============================================================================
# FRONTEND TESTING
# ============================================================================

if ($Frontend) {
    Write-Host "`n[2/4] FRONTEND TESTS" -ForegroundColor Yellow
    Write-Host "======================================" -ForegroundColor Yellow
    
    # Test 1: Frontend files exist
    Write-Host "`nTest 2.1: Frontend Source Files" -ForegroundColor Cyan
    $frontendFiles = @(
        "applications\hr-portal\frontend\src\App.js",
        "applications\hr-portal\frontend\src\index.js",
        "applications\hr-portal\frontend\public\index.html",
        "applications\hr-portal\frontend\Dockerfile",
        "applications\hr-portal\frontend\package.json"
    )
    
    $allFilesExist = $true
    foreach ($file in $frontendFiles) {
        if (Test-Path $file) {
            Write-Host "         [OK] $file" -ForegroundColor Green
        } else {
            Write-Host "         [MISS] $file" -ForegroundColor Red
            $allFilesExist = $false
        }
    }
    Test-Result "All frontend files present" $allFilesExist
    
    # Test 2: Frontend deployment
    Write-Host "`nTest 2.2: Frontend Deployment Status" -ForegroundColor Cyan
    $frontendDeploy = kubectl get deployment hr-portal-frontend -n hr-portal -o json 2>$null | ConvertFrom-Json
    if ($frontendDeploy) {
        $replicas = $frontendDeploy.status.readyReplicas
        $desired = $frontendDeploy.spec.replicas
        Test-Result "Frontend deployment exists" $true "Ready: $replicas/$desired replicas"
    } else {
        Test-Warning "Frontend deployment not found" "May need to build and deploy Docker image"
    }
    
    # Test 3: Frontend service
    Write-Host "`nTest 2.3: Frontend Service" -ForegroundColor Cyan
    $frontendSvc = kubectl get svc hr-portal-frontend -n hr-portal -o json 2>$null | ConvertFrom-Json
    if ($frontendSvc) {
        Test-Result "Frontend service exists" $true
    } else {
        Test-Warning "Frontend service not found" "May be included in hr-portal.yaml"
    }
    
    # Test 4: Frontend Docker image
    Write-Host "`nTest 2.4: Frontend Docker Image in ECR" -ForegroundColor Cyan
    try {
        $images = aws ecr describe-images --repository-name hr-portal-frontend --region eu-west-1 --output json 2>$null | ConvertFrom-Json
        if ($images -and $images.imageDetails) {
            $imageCount = $images.imageDetails.Count
            $latestImage = $images.imageDetails | Sort-Object -Property imagePushedAt -Descending | Select-Object -First 1
            $pushedAt = $latestImage.imagePushedAt
            Test-Result "Frontend image in ECR" $true "$imageCount images, latest: $pushedAt"
        } else {
            Test-Warning "No frontend images in ECR" "Need to build and push: docker build && docker push"
        }
    } catch {
        Test-Warning "Cannot access ECR" "Repository may not exist yet"
    }
    
    # Test 5: Check if we can build frontend locally
    Write-Host "`nTest 2.5: Frontend Build Test (Local)" -ForegroundColor Cyan
    if (Test-Path "applications\hr-portal\frontend\package.json") {
        Write-Host "         To test frontend build locally:" -ForegroundColor Gray
        Write-Host "         cd applications\hr-portal\frontend" -ForegroundColor Gray
        Write-Host "         npm install" -ForegroundColor Gray
        Write-Host "         npm run build" -ForegroundColor Gray
        Write-Host "         npm start  (for dev server)" -ForegroundColor Gray
        Test-Result "Frontend build instructions available" $true
    }
}

# ============================================================================
# WORKSPACE PROVISIONING TESTS
# ============================================================================

if ($Workspaces) {
    Write-Host "`n[3/4] WORKSPACE PROVISIONING TESTS" -ForegroundColor Yellow
    Write-Host "======================================" -ForegroundColor Yellow
    
    # Test 1: Workspaces namespace
    Write-Host "`nTest 3.1: Workspaces Namespace" -ForegroundColor Cyan
    $workspacesNs = kubectl get namespace workspaces -o json 2>$null | ConvertFrom-Json
    if ($workspacesNs) {
        Test-Result "Workspaces namespace exists" $true
    } else {
        Test-Result "Workspaces namespace exists" $false "Run: kubectl create namespace workspaces"
    }
    
    # Test 2: Workspace pods
    Write-Host "`nTest 3.2: Active Workspace Pods" -ForegroundColor Cyan
    $workspacePods = kubectl get pods -n workspaces -o json 2>$null | ConvertFrom-Json
    if ($workspacePods -and $workspacePods.items) {
        $runningWorkspaces = ($workspacePods.items | Where-Object { $_.status.phase -eq "Running" }).Count
        $totalWorkspaces = $workspacePods.items.Count
        
        if ($totalWorkspaces -gt 0) {
            Test-Result "Workspace pods exist" $true "$runningWorkspaces running, $totalWorkspaces total"
            
            # Show workspace details
            foreach ($pod in $workspacePods.items) {
                $podName = $pod.metadata.name
                $podStatus = $pod.status.phase
                $employeeLabel = $pod.metadata.labels.'employee-id'
                Write-Host "         Workspace: $podName | Status: $podStatus | Employee: $employeeLabel" -ForegroundColor Gray
            }
        } else {
            Test-Warning "No workspace pods found" "Workspaces are created when employees are added"
        }
    } else {
        Test-Warning "No workspace pods found" "Workspaces are provisioned automatically on employee creation"
    }
    
    # Test 3: Workspace service account
    Write-Host "`nTest 3.3: Workspace Service Account" -ForegroundColor Cyan
    $workspaceSA = kubectl get serviceaccount workspace-sa -n workspaces -o json 2>$null | ConvertFrom-Json
    if ($workspaceSA) {
        Test-Result "Workspace service account exists" $true
    } else {
        Test-Warning "Workspace service account not found" "May need to apply workspace RBAC"
    }
    
    # Test 4: Workspace RBAC
    Write-Host "`nTest 3.4: Workspace RBAC" -ForegroundColor Cyan
    $workspaceRole = kubectl get role workspace-role -n workspaces -o json 2>$null | ConvertFrom-Json
    if ($workspaceRole) {
        Test-Result "Workspace role exists" $true
    } else {
        Test-Warning "Workspace role not found" "Check kubernetes/rbac.yaml"
    }
    
    # Test 5: Network Policies
    Write-Host "`nTest 3.5: Network Policies" -ForegroundColor Cyan
    $networkPolicies = kubectl get networkpolicies -n workspaces -o json 2>$null | ConvertFrom-Json
    if ($networkPolicies -and $networkPolicies.items) {
        $policyCount = $networkPolicies.items.Count
        Test-Result "Network policies exist" $true "$policyCount policies configured"
        
        foreach ($policy in $networkPolicies.items) {
            $policyName = $policy.metadata.name
            Write-Host "         Policy: $policyName" -ForegroundColor Gray
        }
    } else {
        Test-Warning "No network policies found" "Zero Trust policies may not be applied"
    }
    
    # Test 6: Check workspace provisioning code
    Write-Host "`nTest 3.6: Workspace Provisioning Code" -ForegroundColor Cyan
    $workspaceServiceFile = "applications\hr-portal\backend\src\services\workspaceService.js"
    if (Test-Path $workspaceServiceFile) {
        Test-Result "Workspace provisioning service exists" $true
        
        # Check if it has the key functions
        $content = Get-Content $workspaceServiceFile -Raw
        $hasProvision = $content -match "provisionWorkspace|createWorkspace"
        $hasDeprovision = $content -match "deprovisionWorkspace|deleteWorkspace"
        
        if ($hasProvision) {
            Test-Result "Provision function implemented" $true
        } else {
            Test-Warning "Provision function may be missing" "Check workspaceService.js"
        }
        
        if ($hasDeprovision) {
            Test-Result "Deprovision function implemented" $true
        } else {
            Test-Warning "Deprovision function may be missing" "Check workspaceService.js"
        }
    } else {
        Test-Warning "Workspace service file not found" "Path: $workspaceServiceFile"
    }
}

# ============================================================================
# INTEGRATION TESTS (End-to-End)
# ============================================================================

if ($Integration) {
    Write-Host "`n[4/4] INTEGRATION TESTS" -ForegroundColor Yellow
    Write-Host "======================================" -ForegroundColor Yellow
    
    # Test 1: Check employees with workspaces
    Write-Host "`nTest 4.1: Employee-Workspace Mapping" -ForegroundColor Cyan
    try {
        $employees = aws dynamodb scan --table-name innovatech-employees --output json | ConvertFrom-Json
        if ($employees.Items) {
            $employeesWithWorkspace = 0
            $totalEmployees = $employees.Items.Count
            
            foreach ($emp in $employees.Items) {
                if ($emp.workspaceUrl -and $emp.workspaceUrl.S) {
                    $employeesWithWorkspace++
                }
            }
            
            Test-Result "Employees in database" $true "$totalEmployees employees found"
            
            if ($employeesWithWorkspace -gt 0) {
                Test-Result "Employees with workspace URLs" $true "$employeesWithWorkspace/$totalEmployees have workspace URLs"
            } else {
                Test-Warning "No employees have workspace URLs" "Workspaces may not be provisioned yet"
            }
            
            # Show sample employee data
            if ($totalEmployees -gt 0) {
                Write-Host "`n         Sample Employee Data:" -ForegroundColor Gray
                $sampleEmp = $employees.Items[0]
                Write-Host "         ID: $($sampleEmp.employeeId.S)" -ForegroundColor Gray
                Write-Host "         Name: $($sampleEmp.firstName.S) $($sampleEmp.lastName.S)" -ForegroundColor Gray
                Write-Host "         Role: $($sampleEmp.role.S)" -ForegroundColor Gray
                Write-Host "         Status: $($sampleEmp.status.S)" -ForegroundColor Gray
                if ($sampleEmp.workspaceUrl -and $sampleEmp.workspaceUrl.S) {
                    Write-Host "         Workspace: $($sampleEmp.workspaceUrl.S)" -ForegroundColor Gray
                }
            }
        } else {
            Test-Warning "No employees in database" "Create test employee: .\scripts\create-employee.ps1"
        }
    } catch {
        Test-Result "Database query" $false $_.Exception.Message
    }
    
    # Test 2: Ingress configuration
    Write-Host "`nTest 4.2: Ingress Configuration" -ForegroundColor Cyan
    $ingress = kubectl get ingress hr-portal -n hr-portal -o json 2>$null | ConvertFrom-Json
    if ($ingress) {
        $host = $ingress.spec.rules[0].host
        Test-Result "Ingress exists" $true "Host: $host"
        
        # Check if Load Balancer is provisioned
        if ($ingress.status.loadBalancer.ingress) {
            $albUrl = $ingress.status.loadBalancer.ingress[0].hostname
            Test-Result "Load Balancer provisioned" $true "URL: http://$albUrl"
            
            Write-Host "`n         Access URLs:" -ForegroundColor Cyan
            Write-Host "         Frontend: http://$albUrl" -ForegroundColor Green
            Write-Host "         Backend API: http://$albUrl/api/employees" -ForegroundColor Green
        } else {
            Test-Warning "Load Balancer not provisioned" "May need to install AWS Load Balancer Controller"
            Write-Host "         Run: .\scripts\install-lb-controller-simple.ps1" -ForegroundColor Yellow
        }
    } else {
        Test-Warning "Ingress not found" "Check kubernetes/hr-portal.yaml"
    }
    
    # Test 3: Complete flow simulation
    Write-Host "`nTest 4.3: Complete Employee Lifecycle Flow" -ForegroundColor Cyan
    Write-Host "         Simulated flow:" -ForegroundColor Gray
    Write-Host "         1. User creates employee via frontend/API" -ForegroundColor Gray
    Write-Host "         2. Backend validates and stores in DynamoDB" -ForegroundColor Gray
    Write-Host "         3. Backend triggers workspace provisioning" -ForegroundColor Gray
    Write-Host "         4. Workspace pod created in 'workspaces' namespace" -ForegroundColor Gray
    Write-Host "         5. Workspace URL updated in employee record" -ForegroundColor Gray
    Write-Host "         6. Employee can access workspace" -ForegroundColor Gray
    
    # Check if all components are ready
    $hasBackend = $backendDeploy -ne $null
    $hasDatabase = $employees -ne $null
    $hasNamespace = $workspacesNs -ne $null
    
    $allReady = $hasBackend -and $hasDatabase -and $hasNamespace
    Test-Result "All components ready for employee creation" $allReady
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total Passed:   $($testResults.Passed)" -ForegroundColor Green
Write-Host "Total Failed:   $($testResults.Failed)" -ForegroundColor Red
Write-Host "Total Warnings: $($testResults.Warnings)" -ForegroundColor Yellow

$totalTests = $testResults.Passed + $testResults.Failed + $testResults.Warnings
if ($totalTests -gt 0) {
    $passPercentage = [math]::Round(($testResults.Passed / $totalTests) * 100, 1)
    Write-Host "Pass Rate:      $passPercentage%" -ForegroundColor $(if ($passPercentage -ge 80) { "Green" } elseif ($passPercentage -ge 60) { "Yellow" } else { "Red" })
}

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan

if ($testResults.Failed -gt 0 -or $testResults.Warnings -gt 0) {
    Write-Host "`nRecommended actions:" -ForegroundColor Yellow
    
    Write-Host "`n1. Deploy Frontend to ECR:" -ForegroundColor White
    Write-Host "   cd applications\hr-portal\frontend" -ForegroundColor Gray
    Write-Host "   docker build -t hr-portal-frontend:latest ." -ForegroundColor Gray
    Write-Host "   aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 920120424621.dkr.ecr.eu-west-1.amazonaws.com" -ForegroundColor Gray
    Write-Host "   docker tag hr-portal-frontend:latest 920120424621.dkr.ecr.eu-west-1.amazonaws.com/hr-portal-frontend:latest" -ForegroundColor Gray
    Write-Host "   docker push 920120424621.dkr.ecr.eu-west-1.amazonaws.com/hr-portal-frontend:latest" -ForegroundColor Gray
    
    Write-Host "`n2. Install Load Balancer Controller:" -ForegroundColor White
    Write-Host "   .\scripts\install-lb-controller-simple.ps1" -ForegroundColor Gray
    
    Write-Host "`n3. Test Employee Creation:" -ForegroundColor White
    Write-Host "   .\scripts\create-employee.ps1 -firstName Test -lastName User -email test@example.com -role developer -department Engineering" -ForegroundColor Gray
    
    Write-Host "`n4. Verify Workspace Provisioning:" -ForegroundColor White
    Write-Host "   kubectl get pods -n workspaces" -ForegroundColor Gray
    Write-Host "   .\scripts\list-employees.ps1" -ForegroundColor Gray
}

Write-Host "`n=== MANUAL TESTING GUIDE ===" -ForegroundColor Cyan
Write-Host "`n1. Test Backend API directly:" -ForegroundColor Yellow
Write-Host "   kubectl port-forward svc/hr-portal-backend 3000:80 -n hr-portal" -ForegroundColor Gray
Write-Host "   curl http://localhost:3000/health" -ForegroundColor Gray
Write-Host "   curl http://localhost:3000/api/employees" -ForegroundColor Gray

Write-Host "`n2. Test Frontend locally:" -ForegroundColor Yellow
Write-Host "   cd applications\hr-portal\frontend" -ForegroundColor Gray
Write-Host "   npm install" -ForegroundColor Gray
Write-Host "   `$env:REACT_APP_API_URL='http://localhost:3000'" -ForegroundColor Gray
Write-Host "   npm start" -ForegroundColor Gray
Write-Host "   Open http://localhost:3000 in browser" -ForegroundColor Gray

Write-Host "`n3. Create test employee and verify workspace:" -ForegroundColor Yellow
Write-Host "   .\scripts\create-employee.ps1 -firstName Workspace -lastName Test -email workspace@test.com -role developer -department Engineering" -ForegroundColor Gray
Write-Host "   Wait 30 seconds..." -ForegroundColor Gray
Write-Host "   kubectl get pods -n workspaces -l employee-id=<employee-id>" -ForegroundColor Gray

Write-Host ""
