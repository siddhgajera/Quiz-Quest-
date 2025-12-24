Write-Host "Deploying Firestore Security Rules..." -ForegroundColor Cyan
Write-Host ""

# Check if Firebase CLI is available
try {
    $firebaseVersion = firebase --version 2>$null
    Write-Host "Firebase CLI found: $firebaseVersion" -ForegroundColor Green
} catch {
    Write-Host "Error: Firebase CLI is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Firebase CLI: npm install -g firebase-tools" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if project is initialized
if (-not (Test-Path ".firebaserc")) {
    Write-Host "Error: Firebase project not initialized" -ForegroundColor Red
    Write-Host "Please run: firebase use --add" -ForegroundColor Yellow
    Write-Host "Then select your project" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Deploy the rules
Write-Host "Deploying Firestore rules..." -ForegroundColor Yellow
try {
    firebase deploy --only firestore:rules
    Write-Host ""
    Write-Host "✅ Firestore rules deployed successfully!" -ForegroundColor Green
    Write-Host "Your app should now work without permission errors." -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "❌ Failed to deploy rules. Please check your Firebase project configuration." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to exit"
