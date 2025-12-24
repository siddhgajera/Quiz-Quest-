@echo off
echo Deploying Firestore Security Rules...
echo.

REM Check if Firebase CLI is available
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Firebase CLI is not installed or not in PATH
    echo Please install Firebase CLI: npm install -g firebase-tools
    pause
    exit /b 1
)

REM Check if project is initialized
if not exist .firebaserc (
    echo Error: Firebase project not initialized
    echo Please run: firebase use --add
    echo Then select your project
    pause
    exit /b 1
)

REM Deploy the rules
echo Deploying Firestore rules...
firebase deploy --only firestore:rules

if %errorlevel% equ 0 (
    echo.
    echo ✅ Firestore rules deployed successfully!
    echo Your app should now work without permission errors.
) else (
    echo.
    echo ❌ Failed to deploy rules. Please check your Firebase project configuration.
)

echo.
pause
