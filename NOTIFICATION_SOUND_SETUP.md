# 🔔 AI Daddy - Custom Notification Sound Setup

## ✅ What's Configured

Your app is now ready for **branded notification sounds** that will be part of your app identity!

**Current sound name:** `daddy_notification`

---

## 📱 Android Setup

### 1. Choose Your Sound
- Get a notification sound (1-3 seconds recommended)
- Format: `.mp3`, `.wav`, or `.ogg`
- Free sounds: [NotificationSounds.com](https://notificationsounds.com/) | [Zapsplat](https://www.zapsplat.com/)

### 2. Prepare the File
- **Rename to:** `daddy_notification.mp3` (or .wav/.ogg)
- **Requirements:**
  - Duration: 1-3 seconds
  - Sample Rate: 44100 Hz
  - Bit Rate: 128-320 kbps
  - File Size: Under 500KB

### 3. Add to Project
- **Copy file to:** `android/app/src/main/res/raw/daddy_notification.mp3`
- The `raw` folder already exists

### 4. Rebuild
```bash
flutter clean
flutter build apk
```

---

## 🍎 iOS Setup (Optional)

### 1. Convert Sound to iOS Format
iOS requires `.caf` format. Convert your sound:

**Using macOS/Linux:**
```bash
afconvert -f caff -d LEI16@48000 -c 1 daddy_notification.mp3 daddy_notification.caf
```

**Or use online converter:**
- [Convertio](https://convertio.co/mp3-caf/)
- [CloudConvert](https://cloudconvert.com/mp3-to-caf)

### 2. Add to iOS Project
- **Copy file to:** `ios/Runner/Resources/daddy_notification.caf`
- The `Resources` folder already exists

### 3. Register in Xcode (If building iOS)
1. Open `ios/Runner.xcworkspace` in Xcode
2. Drag `daddy_notification.caf` into Runner folder
3. Check "Copy items if needed"
4. Select "Runner" target

### 4. Rebuild
```bash
flutter clean
flutter build ios
```

---

## 🎵 Sound Behavior

**If sound file exists:**
- Plays your custom branded sound ✅

**If sound file missing:**
- Falls back to system default sound 📢

**Both platforms:**
- Sound plays with notification
- 3 short vibrations (Messenger-style)
- Messenger-style popup
- Works even when app is closed

---

## 🎨 Branding Tips

**Choose a sound that:**
- Is pleasant, not jarring
- Represents your "caring dad" brand
- Is recognizable and unique
- Feels warm and supportive
- Users won't get annoyed by

**Examples:**
- Gentle "ding dong" doorbell
- Soft chime or bell
- Warm notification tone
- Friendly "pop" sound

---

## 🧪 Testing

### After adding sound files:

**Android:**
```bash
flutter build apk
# Install on Android device
# Trigger a reminder
# Should hear your custom sound
```

**iOS:**
```bash
flutter build ios
# Install on iOS device
# Trigger a notification
# Should hear your custom sound
```

---

## 📂 File Locations

```
ai daddy/
├── android/app/src/main/res/raw/
│   ├── README.md                    ✅ Instructions
│   └── daddy_notification.mp3       ⬅️ ADD YOUR SOUND HERE
│
├── ios/Runner/Resources/
│   ├── README.md                    ✅ Instructions
│   └── daddy_notification.caf       ⬅️ ADD YOUR SOUND HERE (iOS)
│
└── lib/services/
    └── notification_service_impl.dart   ✅ Already configured
```

---

## 🔄 Changing Sound Later

To change your brand sound:
1. Replace the sound file (keep same name)
2. Rebuild the app
3. That's it!

---

## ⚙️ Current Configuration

**Code:** Already configured in [notification_service_impl.dart](../lib/services/notification_service_impl.dart)

**Android sound:** `RawResourceAndroidNotificationSound('daddy_notification')`  
**iOS sound:** `'daddy_notification.caf'`

**All notification types use this sound:**
- Daily reminders (5 per day)
- Care thread follow-ups (health, emotion, stress, etc.)
- Instant notifications

---

## ❓ Need Help?

**Sound not playing?**
- Check file exists in correct folder
- Verify filename exactly: `daddy_notification`
- Check file format (.mp3/.wav/.ogg for Android, .caf for iOS)
- Try `flutter clean` and rebuild

**Want to test without rebuilding?**
- Use any `.mp3` file temporarily
- Rename to `daddy_notification.mp3`
- Add to `android/app/src/main/res/raw/`
- Rebuild

---

Your notification sound is now part of your AI Daddy brand! 🎵💙
