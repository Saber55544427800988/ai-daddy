# iOS Custom Notification Sound

## How to Add Your Brand Sound for iOS

1. **Prepare your sound file**
   - Format: `.caf` (Core Audio Format) - **required for iOS**
   - Duration: 1-30 seconds maximum
   - Keep under 30 seconds (iOS limitation)

2. **Convert your sound to .caf format**

   Using command line (macOS/Linux):
   ```bash
   afconvert -f caff -d LEI16@48000 -c 1 your_sound.mp3 daddy_notification.caf
   ```

   Or use online converter:
   - https://convertio.co/mp3-caf/
   - https://cloudconvert.com/mp3-to-caf

3. **Add to iOS project**
   - Copy `daddy_notification.caf` to: `ios/Runner/Resources/`
   - Create `Resources` folder if it doesn't exist

4. **Register in Xcode**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Drag `daddy_notification.caf` into Runner folder
   - Select "Copy items if needed"
   - Select "Runner" target

5. **Rebuild app**
   ```bash
   flutter clean
   flutter pub get
   flutter build ios
   ```

## iOS Sound Requirements

- **Format**: CAF, AIF, or WAV (CAF preferred)
- **Encoding**: Linear PCM or IMA4 (ADPCM)
- **Sample Rate**: 8-48 kHz
- **Duration**: 1-30 seconds
- **File Size**: Under 5MB

## Current Configuration

The app is configured to use: `daddy_notification.caf`

If the file doesn't exist, it will use iOS system default sound.

## Testing

After adding your sound:
1. Build and install on iOS device
2. Trigger a notification
3. Should hear your custom sound

## Notes

- iOS uses different sound format than Android
- You'll need both `daddy_notification.mp3` (Android) and `daddy_notification.caf` (iOS)
- Same brand sound, different formats for each platform
