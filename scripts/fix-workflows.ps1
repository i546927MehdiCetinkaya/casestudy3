# Script to fix GitHub Actions workflows to use IAM role instead of secrets
Write-Host "Fixing GitHub Actions workflows..." -ForegroundColor Cyan

$files = @(
    ".github\workflows\deploy.yml",
    ".github\workflows\destroy.yml"
)

foreach ($file in $files) {
    Write-Host "Processing $file..." -ForegroundColor Yellow
    
    $content = Get-Content $file -Raw
    
    # Replace AWS credentials block with IAM role
    $oldText = "          aws-access-key-id: `${{ secrets.AWS_ACCESS_KEY_ID }}`n          aws-secret-access-key: `${{ secrets.AWS_SECRET_ACCESS_KEY }}`n          aws-session-token: `${{ secrets.AWS_SESSION_TOKEN }}"
    $newText = "          role-to-assume: arn:aws:iam::920120424621:role/githubrepo"
    
    $newContent = $content.Replace($oldText, $newText)
    
    if ($newContent -ne $content) {
        $newContent | Set-Content $file -NoNewline
        Write-Host "  ✓ Fixed $file" -ForegroundColor Green
    } else {
        Write-Host "  - No changes needed in $file" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Done! Workflows now use IAM role authentication." -ForegroundColor Green
