# Play Store Asset Requirements - AI Daddy

## 📋 Checklist of Required Assets

### High-Resolution Icon
- [❌] **512x512 PNG** - High-resolution app icon
  - Format: 32-bit PNG with alpha channel
  - No rounded corners (Google Play adds them)
  - Clean, recognizable icon
  - **Current:** Only have 192x192px icon
  - **Action Required:** Scale up or recreate icon at 512x512

### Feature Graphic
- [❌] **1024x500 PNG or JPG**
  - Used at top of Play Store listing
  - Should represent app brand/purpose
  - Can include app name text
  - **Suggestion:** "AI Daddy" text with caring/supportive imagery (heart, chat bubble, shield)

### Screenshots
**Phone Screenshots (Required - Min 2, Max 8)**
- [❌] **Min resolution:** 320px
- [❌] **Max resolution:** 3840px
- [❌] **Aspect ratio:** 16:9 recommended
- **Suggested screenshots:**
  1. Chat conversation with AI (showing emotional support)
  2. Reminder notification (Messenger-style popup)
  3. Settings screen (show customization)
  4. Care thread activation ("I'm sick" → AI response)
  5. Daily reminder schedule
  6. Emotional state interface (if visible)

**7-inch Tablet Screenshots (Optional - Min 2, Max 8)**
- [❌] Same requirements as phone
- **Recommended** if tablet experience is different

**10-inch Tablet Screenshots (Optional - Min 2, Max 8)**
- [❌] Same requirements as phone

### Promotional Video (Optional)
- [❌] **YouTube URL**
  - 30 seconds to 2 minutes recommended
  - Show app features, emotional support in action
  - Include testimonials or emotional scenarios

---

## 🎨 Quick Asset Creation Guide

### Option 1: Use Existing Icon (Scale Up)
```bash
# If you have vector source (SVG, AI):
# Export at 512x512px
# Save as PNG with transparent background

# If you only have 192x192px:
# Upscale using image editor (Photoshop, GIMP, Canva)
# May lose quality - better to recreate from source
```

### Option 2: Create Icon Online
**Free Tools:**
- **Canva**: https://www.canva.com/ (512x512 custom size)
- **Figma**: https://www.figma.com/ (free, professional)
- **GIMP**: https://www.gimp.org/ (free Photoshop alternative)

**Design Tips:**
- Simple, recognizable at small sizes
- Use blue/purple colors (AI Daddy brand)
- Include "dad" or "AI" symbolism (heart, shield, chat bubble)
- Avoid text in icon (doesn't scale well)

### Option 3: Create Feature Graphic
**Tools:**
- Canva template for "Google Play Feature Graphic"
- Photoshop/GIMP at 1024x500px

**Design Elements:**
- App name: "AI Daddy"
- Tagline: "Your caring AI companion"
- Visual: Chat bubbles, heart, supportive imagery
- Colors: Blue (#5294E2), Purple, White text

### Option 4: Capture Screenshots
**Using Android Emulator:**
1. Open Android Studio
2. Launch emulator (Pixel device recommended)
3. Install APK: `adb install app-release.apk`
4. Launch app and navigate to different screens
5. Capture: Use emulator camera button or `Ctrl+S`

**Using Real Device:**
1. Enable Developer Options
2. Install app
3. Take screenshots (Power + Volume Down)
4. Transfer to PC

**Annotate Screenshots:**
- Use Canva or Figma to add text overlays
- Highlight key features
- Add captions explaining functionality

---

## 📝 Text Assets (Already Complete)

### Short Description ✅
```
Your caring AI dad - daily reminders, emotional support, always here for you 💙
```
(78 characters - within 80 limit)

### Full Description ✅
See `STORE_LISTING.md` for complete description (within 4000 character limit)

---

## 🌍 Localization (Optional)

Consider translating to:
- Spanish (es-ES)
- French (fr-FR)
- German (de-DE)
- Japanese (ja-JP)
- Korean (ko-KR)

Each language needs:
- Short description
- Full description
- Screenshots with translated UI (if UI is localized)

---

## 📊 Google Play Console Setup

### App Information
- **Title:** AI Daddy
- **Short Description:** (see above)
- **Full Description:** (see STORE_LISTING.md)
- **App Category:** Lifestyle (or Health & Fitness)
- **Tags:** AI, Support, Reminders, Mental Health, Dad, Companion
- **Website:** [Your website URL]
- **Email:** [Support email]
- **Phone:** (Optional)
- **Privacy Policy:** [URL to hosted PRIVACY_POLICY.md]

### Content Rating
Complete questionnaire:
- **Violence:** None
- **Sexual Content:** None
- **Profanity:** None
- **Controlled Substances:** None
- **User Interaction:** Chat functionality (AI responses)
- **Data Collection:** Yes (chat messages, emotional data)
- **Shares Location:** No
- **Likely Rating:** Teen (13+)

### Data Safety
- **Collects Data:** Yes
  - Personal info: None (nickname only, not required)
  - Messages: Chat conversations
  - App activity: Usage patterns
  - App info: Version, device type
- **Shares Data:** Yes
  - With LongCat AI for chat processing only
  - Not for advertising or analytics
- **Data Security:**
  - Encrypted in transit (HTTPS)
  - Can delete data (in app settings)
  - No data collection in web version

### Target Audience
- **Primary:** Adults (18+)
- **Secondary:** Teens (13-17) with parental guidance
- **Not for:** Children under 13

### Store Listing Experiments (Optional)
- Test different feature graphics
- Test different screenshot orders
- A/B test descriptions

---

## 🚀 Upload Checklist

Before uploading to Play Console:

**App Bundle (AAB)**
- [❌] Build release AAB (need Android SDK)
- [❌] Verify file size (<150MB)
- [❌] Test install on device

**Store Assets**
- [❌] 512x512 icon
- [❌] 1024x500 feature graphic
- [❌] Min 2 phone screenshots
- [✅] Short description
- [✅] Full description
- [❌] Privacy policy URL

**Play Console Forms**
- [❌] Content rating questionnaire
- [❌] Data safety form
- [❌] Target audience declaration
- [❌] App access (login not required - confirm)
- [❌] Advertising declaration (No ads)

**Optional**
- [ ] Promotional video
- [ ] Tablet screenshots
- [ ] Localized listings
- [ ] Promo codes for reviewers

---

## 🎯 Asset Creation Priority

**Do First (Critical):**
1. Create 512x512 icon (use Canva)
2. Capture 2-3 phone screenshots
3. Host privacy policy online
4. Fix Android SDK issue

**Do Second (Required):**
5. Create feature graphic
6. Capture remaining screenshots (up to 8)
7. Complete Play Console forms

**Do Third (Recommended):**
8. Create promotional video
9. Add tablet screenshots
10. Localize to 2-3 languages

---

## 🌐 Where to Host Privacy Policy

**Free Options:**
1. **GitHub Pages** (Recommended)
   - Create repo: `ai-daddy-privacy`
   - Upload `PRIVACY_POLICY.md`
   - Enable GitHub Pages in Settings
   - URL: `https://[username].github.io/ai-daddy-privacy/`

2. **Google Sites**
   - Create new site
   - Paste privacy policy content
   - Publish
   - URL: `https://sites.google.com/view/ai-daddy-privacy`

3. **Your Website**
   - Upload to your domain
   - URL: `https://yourdomain.com/privacy-policy`

4. **Google Docs (Public)**
   - Create doc, paste policy
   - Share → Anyone with link can view
   - URL: Google Docs link

---

## ⏱️ Estimated Time to Complete

- **Icon creation:** 30 minutes (Canva template)
- **Feature graphic:** 20 minutes (Canva)
- **Screenshots:** 1 hour (capture + annotate)
- **Privacy policy hosting:** 15 minutes (GitHub Pages)
- **Play Console forms:** 30 minutes (questionnaires)
- **Total:** ~2.5 hours

---

**Need help with any specific asset?** Let me know which one to tackle first!
