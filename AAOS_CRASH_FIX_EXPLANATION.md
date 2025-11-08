# AAOS Chromium Crash Fix - Detailed Explanation

## Problem Summary

**Symptoms:**
- Chromium starts successfully on first launch
- Crashes after clicking login
- No logs available
- Subsequent launches fail
- Device: GM Equinox 2024 (AAOS 12)

**Root Cause:**
Your original patch is missing critical permissions and attributes required for Android Automotive OS, particularly for data storage and multi-user support.

## What Was Missing in Your Original Patch

### 1. Storage Permissions (CRITICAL)

**Why it crashes after login:**
When you click login, Chrome needs to:
- Write profile data to disk
- Store cookies and session data
- Create cache directories
- Save browsing history

Without storage permissions, these operations fail silently. On app restart, Chrome tries to read corrupted/incomplete profile data and crashes.

**Added Permissions:**
```xml
<!-- Basic storage access -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<!-- Android 13+ scoped storage -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

### 2. Multi-User Support (CRITICAL for AAOS)

AAOS 12 runs with a headless system user in the background. Apps must support multiple user profiles.

**Added Permission:**
```xml
<uses-permission android:name="android.permission.INTERACT_ACROSS_USERS" />
```

**Added Application Attributes:**
```xml
android:directBootAware="true"          <!-- Works before device unlock -->
android:requiredForAllUsers="true"      <!-- Available to all user profiles -->
```

### 3. Background Service Permissions

Chrome needs to run background sync, downloads, and other services.

**Added Permissions:**
```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />
```

### 4. Android 13+ Notifications

Required for download notifications and other alerts.

**Added Permission:**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### 5. Intent Resolution

Chrome needs to query other packages for sharing, file opening, etc.

**Added Permission:**
```xml
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
```

### 6. AAOS-Specific Metadata

**Added Metadata:**
```xml
<meta-data android:name="android.automotive.launches_on_startup" android:value="false"/>
```

This prevents Chrome from auto-launching on system boot, which could cause memory issues.

## How to Apply the Enhanced Patch

### Option 1: Replace Your Current Patch

```bash
cd ~/chromium_aaos
cp automotive_enhanced.patch automotive.patch
```

### Option 2: Use Enhanced Patch Directly

Edit your `pull_latest.sh` script to reference `automotive_enhanced.patch` instead of `automotive.patch`.

### Rebuild Steps

```bash
cd $CHROMIUMBUILD/chromium/src

# Remove old patch if applied
git reset --hard
git clean -fd

# Apply enhanced patch
cp ~/chromium_aaos/automotive_enhanced.patch .
git apply automotive_enhanced.patch

# Run hooks
gclient runhooks

# Clean previous build
rm -rf out/Release_arm64

# Rebuild
cd ~/chromium_aaos
./build_release.sh
```

## Additional Troubleshooting

### If Still Crashing After Rebuild

1. **Check Package Name Consistency**
   - Ensure `com.CHANGEME.chromium` is replaced with your actual package name
   - Uninstall old version completely before installing new one

2. **Clear App Data on Vehicle**
   - Go to Settings → Apps → Chromium → Storage
   - Clear all data and cache
   - Reinstall the new build

3. **Enable USB Debugging on AAOS**
   - Go to Settings → System → About
   - Tap "Build number" 7 times to enable Developer options
   - Enable USB debugging
   - Connect via `adb` to get logcat output

4. **Get Crash Logs**
   ```bash
   adb connect <vehicle-ip>:5555
   adb logcat -b crash > crash.log
   ```

5. **Check Storage Permissions Granted**
   ```bash
   adb shell dumpsys package com.CHANGEME.chromium | grep permission
   ```

### Known AAOS 12 Limitations

1. **Flash Memory Management**
   - AAOS 12L has aggressive write limits
   - Chrome might be disabled if it writes too much data
   - Monitor with: `adb shell dumpsys car_watchdog`

2. **Multi-User Profile Conflicts**
   - Each AAOS user gets separate app data
   - Switching users might cause issues
   - Test with single user first

3. **Vehicle-Specific Restrictions**
   - GM might have additional restrictions
   - Some permissions might require system signature
   - Consider testing on Android Automotive emulator first

## Testing Checklist

After rebuilding with enhanced patch:

- [ ] App installs successfully
- [ ] App launches without crash
- [ ] Can browse websites
- [ ] Can click login (Google account)
- [ ] App restarts successfully after login
- [ ] Data persists across app restarts
- [ ] Works after vehicle reboot
- [ ] Works with multiple user profiles (if applicable)
- [ ] Downloads work properly
- [ ] Media playback works

## Why No Logs?

AAOS restricts log access for security. To get logs:

1. Enable Developer Options (tap Build Number 7 times)
2. Enable USB debugging
3. Connect via ADB (wireless or wired)
4. Use `adb logcat` to see real-time logs
5. Check `/data/tombstones/` for crash dumps

## Comparison: Original vs Enhanced Patch

| Feature | Original Patch | Enhanced Patch |
|---------|---------------|----------------|
| Automotive hardware requirement | ✅ | ✅ |
| Distraction optimized | ✅ | ✅ |
| Storage permissions | ❌ | ✅ |
| Multi-user support | ❌ | ✅ |
| Background services | ❌ | ✅ |
| Direct boot aware | ❌ | ✅ |
| Required for all users | ❌ | ✅ |
| Android 13+ permissions | ❌ | ✅ |
| Intent resolution | ❌ | ✅ |
| AAOS startup control | ❌ | ✅ |

## Expected Outcome

After applying the enhanced patch and rebuilding:

1. ✅ Chrome will launch successfully
2. ✅ Login will work without crashing
3. ✅ Profile data will persist properly
4. ✅ App will restart without issues
5. ✅ Multi-user profiles will work correctly

## Need More Help?

If you still experience crashes after applying this patch:

1. Get logcat output via ADB
2. Check `/data/tombstones/` for native crashes
3. Verify all permissions are granted in Settings → Apps
4. Test on Android Automotive emulator to isolate vehicle-specific issues
5. Consider checking GM Equinox specific restrictions

## References

- [AAOS Multi-User Support](https://source.android.com/docs/automotive/users_accounts/multi_user)
- [Android Automotive Permissions](https://developer.android.com/training/cars/apps#declare-automotive-features)
- [AAOS 12L Release Notes](https://source.android.com/docs/automotive/start/releases/sl_release)
