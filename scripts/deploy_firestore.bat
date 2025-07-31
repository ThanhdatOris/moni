@echo off
echo Deploying Firestore indexes and rules...

echo.
echo Checking Firebase CLI...
firebase --version
if %errorlevel% neq 0 (
    echo Firebase CLI not found. Please install it first:
    echo npm install -g firebase-tools
    exit /b 1
)

echo.
echo Logging in to Firebase...
firebase login

echo.
echo Deploying Firestore rules...
firebase deploy --only firestore:rules

echo.
echo Deploying Firestore indexes...
firebase deploy --only firestore:indexes

echo.
echo Deployment completed!
echo.
echo Note: Indexes may take several minutes to build.
echo Check the Firebase Console for index build status.

pause 