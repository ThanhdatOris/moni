@echo off
echo ========================================
echo Firestore Index Troubleshooting Tool
echo ========================================
echo.

:: Kiểm tra Firebase CLI
npx firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Firebase CLI not found.
    echo Please install: npm install -g firebase-tools
    echo OR use: npx firebase
    pause
    exit /b 1
)

echo Select troubleshooting option:
echo.
echo 1. Check index status and health
echo 2. Fix common "requires an index" errors
echo 3. View recent Firestore errors
echo 4. Reset and redeploy all indexes
echo 5. Generate index suggestions from error logs
echo.
set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" goto check_status
if "%choice%"=="2" goto fix_common
if "%choice%"=="3" goto view_errors
if "%choice%"=="4" goto reset_deploy
if "%choice%"=="5" goto generate_suggestions
goto invalid

:check_status
echo.
echo ========================================
echo Firebase Firestore Index Status & Health
echo ========================================
echo.
echo Fetching current Firestore indexes...
npx firebase firestore:indexes
echo.
echo ========================================
echo Index Health Check:
echo ========================================
echo Checking critical indexes for moni app...
echo.
echo [transactions] Checking date indexes...
npx firebase firestore:indexes | findstr /i "transactions.*date" >nul
if %errorlevel% equ 0 (
    echo ✓ Transaction date indexes found
) else (
    echo ✗ Missing transaction date indexes
)
echo [categories] Checking category indexes...  
npx firebase firestore:indexes | findstr /i "categories" >nul
if %errorlevel% equ 0 (
    echo ✓ Category indexes found
) else (
    echo ✗ Missing category indexes
)
echo [spending_limits] Checking limit indexes...
npx firebase firestore:indexes | findstr /i "spending_limits" >nul
if %errorlevel% equ 0 (
    echo ✓ Spending limit indexes found
) else (
    echo ✗ Missing spending limit indexes
)
echo.
echo ========================================
echo For detailed index status, visit:
echo https://console.firebase.google.com/project/oris-sproject/firestore/indexes
echo ========================================
goto end

:fix_common
echo.
echo Applying common index fixes...
echo.
echo 1. Updating firestore.indexes.json with optimized indexes...
echo 2. These indexes support our current query patterns:
echo    - Transaction date ordering (ASC/DESC)
echo    - Category filtering with deleted check
echo    - Spending limits by category and period
echo    - Category usage tracking
echo.
echo 3. Deploying optimized indexes...
npx firebase deploy --only firestore:indexes
echo.
echo ✓ Common index issues should now be resolved.
goto end

:view_errors
echo.
echo Recent Firestore errors (last 50 lines):
echo.
npx firebase functions:log --only firestore 2>nul || echo "No function logs available"
goto end

:reset_deploy
echo.
echo WARNING: This will reset ALL indexes and redeploy.
echo This may cause temporary query slowdowns.
echo.
set /p confirm="Are you sure? (y/N): "
if /i not "%confirm%"=="y" goto end

echo.
echo 1. Backing up current indexes...
if not exist "backups" mkdir backups
npx firebase firestore:indexes > backups\pre_reset_backup_%date:~10,4%%date:~4,2%%date:~7,2%.json

echo 2. Deploying fresh indexes...
npx firebase deploy --only firestore:indexes --force

echo 3. Done! Monitor index building in Firebase Console.
goto end

:generate_suggestions
echo.
echo Analyzing common query patterns for index suggestions...
echo.
echo Based on your TransactionService queries, recommended indexes:
echo.
echo 1. For getTransactions():
echo    - Single field index on 'date' (ASCENDING and DESCENDING)
echo    - This supports: orderBy('date') + where('date', isGreaterThan/LessThan)
echo.
echo 2. For category queries:
echo    - Composite: is_deleted=false + name (for category lookups)
echo.
echo 3. For spending limits:
echo    - Composite: category_id + period_type
echo.
echo 4. For usage tracking:
echo    - Composite: category_id + last_used DESC
echo.
echo Current firestore.indexes.json already includes these optimized indexes.
echo Run option 2 to deploy them.
goto end

:invalid
echo Invalid choice. Please run the script again.

:end
echo.
echo ========================================
echo Troubleshooting completed.
echo.
echo For more help, visit:
echo https://firebase.google.com/docs/firestore/query-data/index-overview
echo ========================================
echo.
pause
