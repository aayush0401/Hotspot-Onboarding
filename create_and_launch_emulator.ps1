# Create and launch Android emulator for testing
# This script creates a Pixel 6 API 33 AVD if it doesn't exist and launches it

Write-Host "Checking for existing Android emulators..." -ForegroundColor Cyan

# Check if avdmanager is available
$avdmanager = Get-Command avdmanager -ErrorAction SilentlyContinue
if (-not $avdmanager) {
    Write-Host "ERROR: avdmanager not found. Please ensure Android SDK is installed and ANDROID_HOME is set." -ForegroundColor Red
    Write-Host "Install Android Studio from: https://developer.android.com/studio" -ForegroundColor Yellow
    exit 1
}

# List existing AVDs
Write-Host "`nExisting AVDs:" -ForegroundColor Cyan
& avdmanager list avd

# Define AVD name
$avdName = "Flutter_Test_Pixel6_API33"

# Check if our AVD exists
$existingAvds = & avdmanager list avd | Select-String -Pattern $avdName
if ($existingAvds) {
    Write-Host "`nAVD '$avdName' already exists." -ForegroundColor Green
} else {
    Write-Host "`nCreating new AVD: $avdName" -ForegroundColor Yellow
    Write-Host "This will create a Pixel 6 emulator with API 33 (Android 13)..." -ForegroundColor Yellow
    
    # Create the AVD (using system image if installed)
    # Note: You may need to install the system image first via Android Studio SDK Manager
    & echo "no" | avdmanager create avd -n $avdName -k "system-images;android-33;google_apis_playstore;x86_64" -d "pixel_6"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "AVD created successfully!" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Failed to create AVD. You may need to install system image 'system-images;android-33;google_apis_playstore;x86_64'" -ForegroundColor Red
        Write-Host "Open Android Studio > SDK Manager > SDK Platforms > Android 13 (API 33) and install the Google Play system image." -ForegroundColor Yellow
        exit 1
    }
}

# Launch the emulator
Write-Host "`nLaunching emulator '$avdName'..." -ForegroundColor Cyan
Write-Host "This will take 30-60 seconds to boot. Please wait..." -ForegroundColor Yellow

# Start emulator in background
Start-Process -FilePath "emulator" -ArgumentList "-avd", $avdName -NoNewWindow

# Wait for device to be ready
Write-Host "`nWaiting for emulator to boot..." -ForegroundColor Cyan
$timeout = 120  # 2 minutes timeout
$elapsed = 0
$booted = $false

while ($elapsed -lt $timeout) {
    Start-Sleep -Seconds 3
    $elapsed += 3
    
    # Check if device is ready
    $devices = & adb devices | Select-String "emulator-.*\sdevice$"
    if ($devices) {
        $booted = $true
        break
    }
    
    Write-Host "." -NoNewline
}

Write-Host ""

if ($booted) {
    Write-Host "`nEmulator booted successfully!" -ForegroundColor Green
    Write-Host "`nYou can now run:" -ForegroundColor Cyan
    Write-Host "  flutter devices" -ForegroundColor White
    Write-Host "  flutter run --dart-define=USE_MOCK=true" -ForegroundColor White
} else {
    Write-Host "`nWARNING: Emulator may still be booting. Check Android Studio or run 'adb devices' to verify." -ForegroundColor Yellow
}
