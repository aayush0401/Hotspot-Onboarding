# Connect Samsung Device for Flutter Development

## Your Device: Samsung SM-G610F (Galaxy J7 Prime)
- **OS**: Android 8.1.0 (API 27)
- **Status**: Currently not detected by Flutter

---

## Step-by-Step Setup Guide

### Step 1: Enable Developer Options
1. Open **Settings** on your Samsung phone
2. Scroll down to **About Phone**
3. Find **Build Number**
4. **Tap "Build Number" 7 times** rapidly
5. You'll see a message: "You are now a developer!"

### Step 2: Enable USB Debugging
1. Go back to **Settings**
2. Find **Developer Options** (usually near the bottom)
3. Toggle **Developer Options** to **ON**
4. Scroll down and enable:
   - ✅ **USB Debugging** (CRITICAL)
   - ✅ **Install via USB** (if available)
   - ✅ **USB Debugging (Security Settings)** (if available)

### Step 3: Connect USB Cable
1. Use a **good quality USB cable** (preferably the original Samsung cable)
2. Connect your phone to the computer
3. Make sure the cable supports **data transfer** (not charging-only)

### Step 4: Change USB Mode
When you connect the phone, a notification will appear:

1. Tap the **"Charging this device via USB"** notification
2. Select **"File Transfer"** or **"MTP (Media Transfer Protocol)"**
3. Do NOT use "Charging only" mode

### Step 5: Accept RSA Fingerprint
1. A popup will appear on your phone: **"Allow USB debugging?"**
2. Check the box: **"Always allow from this computer"**
3. Tap **"OK"**

### Step 6: Verify Connection
Run this command in PowerShell:
```powershell
& "C:\Users\aayus\AppData\Local\Android\sdk\platform-tools\adb.exe" devices
```

**Expected output** (when successful):
```
List of devices attached
RZCX52CNV3M     device
```

If you see "unauthorized" instead of "device", repeat Step 5.

### Step 7: Verify with Flutter
```powershell
cd "d:\8CLUB ASSIGNMENT\hotspot_onboarding"
flutter devices
```

**Expected output**:
```
Found 4 connected devices:
  SM G610F (mobile) • RZCX52CNV3M • android-arm64 • Android 8.1.0 (API 27)
  Windows (desktop) • windows • windows-x64    • Microsoft Windows
  Chrome (web)      • chrome  • web-javascript • Google Chrome
  Edge (web)        • edge    • web-javascript • Microsoft Edge
```

### Step 8: Run the App
```powershell
flutter run -d RZCX52CNV3M
```

Or if there's only one physical device connected:
```powershell
flutter run
```

Flutter will automatically select your Samsung device.

---

## Troubleshooting

### Problem: "unauthorized" in adb devices
**Solution**: 
- Unplug and replug USB cable
- Revoke USB debugging: Settings > Developer Options > Revoke USB Debugging Authorizations
- Try Step 5 again

### Problem: No popup for "Allow USB debugging?"
**Solution**:
- Try a different USB cable
- Try a different USB port on your computer
- Restart ADB: 
  ```powershell
  & "C:\Users\aayus\AppData\Local\Android\sdk\platform-tools\adb.exe" kill-server
  & "C:\Users\aayus\AppData\Local\Android\sdk\platform-tools\adb.exe" start-server
  ```

### Problem: Device still not showing in flutter devices
**Solution**:
1. Check if device shows in adb:
   ```powershell
   & "C:\Users\aayus\AppData\Local\Android\sdk\platform-tools\adb.exe" devices
   ```
2. If yes, but not in flutter devices, try:
   ```powershell
   flutter doctor -v
   flutter devices --device-timeout=60
   ```

### Problem: "Waiting for another flutter command to release the startup lock"
**Solution**:
```powershell
taskkill /F /IM dart.exe
taskkill /F /IM flutter.exe
```

### Problem: App installs but crashes immediately
**Check**:
- Android version compatibility (your device is API 27, minimum required is usually API 21)
- Permissions in AndroidManifest.xml (already configured)
- Build errors in terminal output

---

## Alternative: Use Android Emulator

If you can't connect your physical device, you can use an emulator:

### Create Emulator
```powershell
flutter emulators --create
```

### List Available Emulators
```powershell
flutter emulators
```

### Launch Emulator
```powershell
flutter emulators --launch <emulator_id>
```

### Run App on Emulator
```powershell
flutter run
```

**Note**: Emulators are slower but easier to set up.

---

## Once Connected: Testing Checklist

After successfully connecting your Samsung device, test these features:

### 1. Experience Selection Screen
- [ ] Images load correctly (no CORS issues on mobile!)
- [ ] Can select multiple experiences
- [ ] Grayscale effect on unselected cards
- [ ] Text field accepts input (250 char limit)
- [ ] "Next" button validates selection (3+ required)

### 2. Onboarding Question Screen
- [ ] Text field works (600 char limit)
- [ ] Camera permission requested correctly
- [ ] Can record video
- [ ] Video preview shows after recording
- [ ] Can stop/start recording

### 3. Performance
- [ ] Smooth scrolling in grid
- [ ] No lag during recording
- [ ] Images load quickly (cached after first load)

### 4. UI/UX
- [ ] Text is readable
- [ ] Buttons are touchable
- [ ] Layout looks good on device screen
- [ ] Dark theme displays correctly

---

## Expected Installation Time

**First Installation**: 2-5 minutes
- Gradle build
- APK generation
- Installation to device
- App launch

**Hot Reload** (after changes): 1-3 seconds

**Hot Restart**: 5-10 seconds

---

## Useful Commands Reference

```powershell
# Check connected devices
flutter devices

# Run on specific device
flutter run -d RZCX52CNV3M

# Clean build
flutter clean
flutter pub get
flutter run

# Build release APK
flutter build apk --release

# Install release APK manually
& "C:\Users\aayus\AppData\Local\Android\sdk\platform-tools\adb.exe" install build/app/outputs/flutter-apk/app-release.apk

# View device logs
& "C:\Users\aayus\AppData\Local\Android\sdk\platform-tools\adb.exe" logcat

# Check device info
& "C:\Users\aayus\AppData\Local\Android\sdk\platform-tools\adb.exe" shell getprop ro.build.version.release
```

---

## What's Different on Android vs Web?

### Images
- ✅ **Android**: Full images load from CloudFront (no CORS issues)
- ⚠️ **Web**: Gradient placeholders only

### Camera
- ✅ **Android**: Full camera access for video recording
- ❌ **Web**: Camera recording skipped (not supported well)

### Permissions
- ✅ **Android**: Runtime permission dialogs
- ❌ **Web**: Browser permission prompts (limited)

### Performance
- ✅ **Android**: Native performance, smooth 60fps
- ⚠️ **Web**: Slightly slower, browser-dependent

---

## Need Help?

1. **Check terminal output** for specific error messages
2. **Take screenshots** of any errors on the device
3. **Check Android logs**:
   ```powershell
   & "C:\Users\aayus\AppData\Local\Android\sdk\platform-tools\adb.exe" logcat *:E
   ```
4. **Verify Flutter doctor**:
   ```powershell
   flutter doctor -v
   ```

---

**Last Updated**: 2025-01-13  
**Device**: Samsung SM-G610F (Galaxy J7 Prime, Android 8.1.0)  
**Status**: Waiting for USB connection
