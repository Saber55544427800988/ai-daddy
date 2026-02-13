# Android SDK Setup Guide

## ❌ Current Issue
```
Error: No Android SDK found. Try setting the ANDROID_HOME environment variable.
```

## ✅ Solution: Install Android Studio

### Option 1: Install Android Studio (Recommended)

1. **Download Android Studio**
   - Visit: https://developer.android.com/studio
   - Download for Windows
   - File size: ~1GB installer

2. **Install Android Studio**
   - Run installer
   - Choose "Standard" installation
   - Accept all SDK component licenses
   - Wait for SDK components to download (~3-5GB)

3. **Configure Flutter**
   ```bash
   # After installation, Flutter will auto-detect
   flutter doctor
   
   # Should now show:
   # [✓] Android toolchain - develop for Android devices (Android SDK version XX)
   ```

4. **Accept Android Licenses**
   ```bash
   flutter doctor --android-licenses
   # Type 'y' to accept all licenses
   ```

5. **Verify Setup**
   ```bash
   flutter doctor -v
   # All Android toolchain checks should pass
   ```

---

### Option 2: Use Existing Android SDK

If you already have Android SDK installed elsewhere:

1. **Find Android SDK Location**
   - Common locations:
     - `C:\Users\[Username]\AppData\Local\Android\Sdk`
     - `C:\Android\Sdk`
     - `C:\Program Files\Android\Sdk`

2. **Set ANDROID_HOME Environment Variable**
   
   **Method A: PowerShell (Temporary)**
   ```powershell
   $env:ANDROID_HOME = "C:\Users\YourUsername\AppData\Local\Android\Sdk"
   $env:PATH += ";$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\tools"
   ```

   **Method B: System Environment Variables (Permanent)**
   1. Press `Win + X` → System
   2. Click "Advanced system settings"
   3. Click "Environment Variables"
   4. Under "User variables", click "New"
   5. Variable name: `ANDROID_HOME`
   6. Variable value: `C:\path\to\your\android\sdk`
   7. Click OK
   8. Edit "Path" variable
   9. Add new entries:
      - `%ANDROID_HOME%\platform-tools`
      - `%ANDROID_HOME%\tools`
   10. Click OK and restart terminal

3. **Configure Flutter**
   ```bash
   flutter config --android-sdk "C:\path\to\your\android\sdk"
   ```

4. **Verify**
   ```bash
   flutter doctor -v
   ```

---

### Option 3: Use Android Command Line Tools Only (Advanced)

If you don't want full Android Studio:

1. **Download Command Line Tools**
   - Visit: https://developer.android.com/studio#command-tools
   - Download "Command line tools only"

2. **Extract and Setup**
   ```powershell
   # Extract to C:\Android\cmdline-tools
   # Create SDK folder structure
   mkdir C:\Android\Sdk
   mkdir C:\Android\Sdk\cmdline-tools\latest
   # Move extracted files to latest folder
   ```

3. **Install SDK Packages**
   ```powershell
   cd C:\Android\Sdk\cmdline-tools\latest\bin
   .\sdkmanager.bat "platform-tools" "platforms;android-34" "build-tools;34.0.0"
   ```

4. **Set Environment Variables** (see Option 2, Method B)

5. **Configure Flutter**
   ```bash
   flutter config --android-sdk "C:\Android\Sdk"
   flutter doctor --android-licenses
   ```

---

## 🔍 Verify Installation

After setup, run:

```bash
flutter doctor -v
```

**Expected output:**
```
[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
    • Android SDK at C:\Users\[Username]\AppData\Local\Android\Sdk
    • Platform android-34, build-tools 34.0.0
    • Java binary at: C:\Program Files\Android Studio\jbr\bin\java
    • Java version OpenJDK Runtime Environment
    • All Android licenses accepted.
```

---

## 🚀 Build App After Setup

Once Android SDK is configured:

```bash
# Navigate to project
cd "D:\mobile apps\ai daddy"

# Clean previous build
flutter clean

# Build release AAB for Play Store
flutter build appbundle --release

# Output location:
# build/app/outputs/bundle/release/app-release.aab
```

---

## 🐛 Common Issues

### Issue: "cmdline-tools component is missing"
**Fix:**
```bash
# In Android Studio:
# Tools → SDK Manager → SDK Tools
# Check "Android SDK Command-line Tools"
# Click Apply
```

### Issue: "Java not found"
**Fix:**
- Android Studio includes JDK
- Ensure Android Studio is installed fully
- Or download JDK 17: https://adoptium.net/

### Issue: "Licenses not accepted"
**Fix:**
```bash
flutter doctor --android-licenses
# Type 'y' for each prompt
```

### Issue: "Build tools version not found"
**Fix:**
```bash
# In Android Studio:
# Tools → SDK Manager → SDK Tools
# Check "Android SDK Build-Tools 34"
# Click Apply
```

---

## ⏱️ Estimated Time

- **Option 1 (Android Studio):** 30-45 minutes (including download)
- **Option 2 (Existing SDK):** 5-10 minutes
- **Option 3 (Command Line):** 15-20 minutes

---

## 📋 After SDK Setup

Return to Play Store preparation:

1. ✅ Build AAB: `flutter build appbundle --release`
2. ❌ Create 512x512 icon (see PLAY_STORE_ASSETS_GUIDE.md)
3. ❌ Capture screenshots
4. ❌ Host privacy policy
5. ❌ Complete Play Console forms

**Recommended next step:** Install Android Studio (Option 1) - it's the most complete solution and includes emulators for testing.
