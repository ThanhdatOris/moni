# Simple Firebase Index Deployment for Moni

Write-Host "Firebase Index Deployment for Moni" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Check CLI
Write-Host "Checking Firebase CLI..." -ForegroundColor Yellow
$version = npx firebase --version
Write-Host "Firebase CLI: $version" -ForegroundColor Green

# Show current indexes
Write-Host "`nCurrent indexes:" -ForegroundColor Yellow
npx firebase firestore:indexes

# Deploy new indexes
Write-Host "`nDeploying indexes..." -ForegroundColor Yellow
npx firebase deploy --only firestore:indexes

# Show result
Write-Host "`nUpdated indexes:" -ForegroundColor Yellow  
npx firebase firestore:indexes

Write-Host "`nDeployment completed!" -ForegroundColor Green
Write-Host "Check Firebase Console for build status." -ForegroundColor Cyan
