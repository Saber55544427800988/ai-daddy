# Custom Notification Sound

## How to Add Your Brand Sound

1. **Choose your sound file** (.mp3, .wav, or .ogg format)
   - Keep it short: 1-3 seconds
   - Clear, pleasant tone that represents your brand
   - Not too loud or jarring

2. **Rename the file to:** `daddy_notification.mp3` (or .wav/.ogg)

3. **Copy it to this folder:** `android/app/src/main/res/raw/`

4. **Rebuild the app**

## File Requirements

- **Format**: MP3, WAV, or OGG
- **Duration**: 1-3 seconds recommended
- **File Size**: Under 500KB recommended
- **Sample Rate**: 44100 Hz or 48000 Hz
- **Bit Rate**: 128-320 kbps for MP3

## Current Configuration

The app is configured to use: `daddy_notification`

If the file doesn't exist, it will fall back to system default sound.

## Free Sound Resources

- **Notification Sounds**: https://notificationsounds.com/
- **Zapsplat**: https://www.zapsplat.com/ (free sound effects)
- **Freesound**: https://freesound.org/
- **YouTube Audio Library**: Creative Commons sounds

## Testing

After adding your sound:
1. Rebuild app: `flutter build apk`
2. Install on device
3. Trigger a notification
4. Sound should play immediately
