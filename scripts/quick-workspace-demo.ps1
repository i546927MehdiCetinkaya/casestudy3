# Quick Fix: Use emptyDir instead of PVC for demo purposes
# This allows the workspace to run immediately without EBS CSI driver

Write-Host "`n=== Quick Demo Fix: Using emptyDir Volumes ===" -ForegroundColor Cyan
Write-Host "This will patch the henk-de-boer workspace to use emptyDir instead of PVC`n" -ForegroundColor Yellow

# Delete the pending pod and PVC
Write-Host "1. Cleaning up pending resources..." -ForegroundColor Yellow
kubectl delete pod henk-de-boer -n workspaces
kubectl delete pvc henk-de-boer-pvc -n workspaces

Write-Host "`n2. Creating new pod with emptyDir..." -ForegroundColor Yellow

# Create pod with emptyDir
@"
apiVersion: v1
kind: Pod
metadata:
  name: henk-de-boer
  namespace: workspaces
  labels:
    app: workspace
    employee: henk-de-boer
    role: manager
    workspaceId: ed7f34ba-e588-4e03-85aa-1fb30564b7f7
spec:
  serviceAccountName: workspace-provisioner
  containers:
  - name: code-server
    image: 920120424621.dkr.ecr.eu-west-1.amazonaws.com/employee-workspace:latest
    imagePullPolicy: Always
    ports:
    - containerPort: 8080
      name: http
    env:
    - name: EMPLOYEE_ID
      value: "53ca035a-f022-47b6-a975-02fa2d1da113"
    - name: EMPLOYEE_EMAIL
      value: "henkdeboer@gmail.com"
    - name: EMPLOYEE_ROLE
      value: "manager"
    - name: PASSWORD
      valueFrom:
        secretKeyRef:
          name: henk-de-boer-secret
          key: password
    volumeMounts:
    - name: workspace-storage
      mountPath: /home/coder/workspace
    - name: tmp
      mountPath: /tmp
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1000m"
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
  volumes:
  - name: workspace-storage
    emptyDir: {}
  - name: tmp
    emptyDir: {}
"@ | kubectl apply -f -

Write-Host "`n3. Waiting for pod to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

kubectl get pods henk-de-boer -n workspaces

Write-Host "`n4. Checking pod status..." -ForegroundColor Yellow
$POD_STATUS = (kubectl get pod henk-de-boer -n workspaces -o jsonpath='{.status.phase}')
Write-Host "Pod Status: $POD_STATUS" -ForegroundColor $(if($POD_STATUS -eq 'Running'){'Green'}else{'Yellow'})

if ($POD_STATUS -eq "Running") {
    Write-Host "`n✅ SUCCESS! Workspace pod is running!" -ForegroundColor Green
    Write-Host "`n⚠️  NOTE: Using emptyDir - data will be lost if pod restarts" -ForegroundColor Yellow
    Write-Host "For persistent storage, install EBS CSI driver`n" -ForegroundColor Yellow
} else {
    Write-Host "`n⏳ Pod is starting... Check logs:" -ForegroundColor Yellow
    Write-Host "kubectl logs henk-de-boer -n workspaces`n" -ForegroundColor Cyan
}

Write-Host "`nWorkspace Details:" -ForegroundColor Cyan
Write-Host "  Employee: Henk de Boer" -ForegroundColor White
Write-Host "  Workspace ID: ed7f34ba-e588-4e03-85aa-1fb30564b7f7" -ForegroundColor White
Write-Host "  Ingress: henk-de-boer.workspaces.innovatech.example.com`n" -ForegroundColor White
