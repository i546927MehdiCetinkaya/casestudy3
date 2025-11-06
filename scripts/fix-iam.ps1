# Script to fix GitHub Actions workflows to use IAM role
Write-Host "Fixing workflows to use IAM role..." -ForegroundColor Cyan

$deployFile = ".github\workflows\deploy.yml"
$destroyFile = ".github\workflows\destroy.yml"

# Fix deploy.yml
$content = Get-Content $deployFile -Raw
$old = "          aws-access-key-id: `${{ secrets.AWS_ACCESS_KEY_ID }}`r`n          aws-secret-access-key: `${{ secrets.AWS_SECRET_ACCESS_KEY }}`r`n          aws-session-token: `${{ secrets.AWS_SESSION_TOKEN }}"
$new = "          role-to-assume: arn:aws:iam::920120424621:role/githubrepo"
$content = $content.Replace($old, $new)
Set-Content $deployFile -Value $content -NoNewline
Write-Host "Fixed deploy.yml" -ForegroundColor Green

# Fix destroy.yml  
$content = Get-Content $destroyFile -Raw
$content = $content.Replace($old, $new)
Set-Content $destroyFile -Value $content -NoNewline
Write-Host "Fixed destroy.yml" -ForegroundColor Green

Write-Host "Done!" -ForegroundColor Cyan
