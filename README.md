# 🛡️ TrustShield AI

**AI-Powered Digital Trust & Scam Protection Platform**  
*Know Before You Trust*

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK ≥ 3.3.0 ([Install Flutter](https://docs.flutter.dev/get-started/install/windows))
- Android Studio / VS Code
- Firebase project set up (see below)
- Node.js 20+ (for Cloud Functions)

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Firebase Setup
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Open project **trustshieldai-8f2fd**
3. Enable:
   - **Authentication** → Email/Password + Google Sign-In
   - **Cloud Firestore** → Start in Production mode
   - **Cloud Storage**
   - **Cloud Functions**
4. Download `google-services.json` → place in `android/app/`
5. Add your Android app SHA-1 fingerprint for Google Sign-In

### 3. Set Gemini API Key
```bash
# In Firebase CLI
firebase functions:config:set gemini.api_key="YOUR_GEMINI_API_KEY"
```
Get your key from [Google AI Studio](https://aistudio.google.com/app/apikey)

### 4. Deploy Cloud Functions
```bash
cd functions
npm install
firebase deploy --only functions
```

### 5. Run the App
```bash
flutter run
```

---

## 📱 Features

| Module | Description |
|--------|-------------|
| 🔍 **Message Scanner** | AI analysis of WhatsApp/SMS/email messages |
| 🔗 **URL Intelligence** | Domain safety, phishing detection |
| 📄 **Offer Letter Verifier** | OCR + AI document authentication |
| ✅ **Fact Checker** | Claim verification with evidence |
| 🤖 **AI Assistant** | Gemini cybersecurity chatbot |
| 🌐 **Community Network** | Crowdsourced threat intelligence |
| 🔔 **Notification Monitor** | Real-time background protection |
| 📊 **Scan History** | Full audit trail with analytics |
| 👤 **Admin Dashboard** | User & platform management |

---

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── providers/       # Riverpod providers (auth, theme)
│   ├── router/          # GoRouter configuration
│   ├── services/        # AI service, scan history service
│   ├── shell/           # Bottom nav shell
│   ├── theme/           # App colors, typography
│   └── widgets/         # GlassCard, PrimaryButton, TrustScoreGauge
├── features/
│   ├── auth/            # Login, Signup, Forgot Password, Splash
│   ├── home/            # Dashboard with quick actions
│   ├── scanner/         # Message + URL scanners
│   ├── document/        # Offer letter OCR verifier
│   ├── fact_check/      # Fact checking module
│   ├── community/       # Community threat feed
│   ├── assistant/       # AI chatbot
│   ├── history/         # Scan history
│   ├── profile/         # User profile
│   ├── settings/        # App settings + notification monitor
│   └── admin/           # Admin dashboard
└── firebase_options.dart
```

---

## 🔐 Notification Listener Setup (Android)

The app requires Notification Listener Service permission to monitor messages:

1. Open app → Settings → Enable "Notification Listener"
2. OR manually: Android Settings → Apps → Special App Access → Notification Access → TrustShield AI

---

## 🚢 Build & Deploy

### Debug APK
```bash
flutter build apk --debug
```

### Release APK (requires keystore)
```bash
# Generate keystore (one-time)
keytool -genkey -v -keystore android/app/trustshield-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias trustshield

# Build
flutter build apk --release --split-per-abi
```

### App Bundle (Play Store)
```bash
flutter build appbundle --release
```

---

## 📊 Tech Stack

- **Flutter** 3.3.0+ — Cross-platform UI
- **Riverpod** 2.x — State management
- **GoRouter** 14.x — Navigation
- **Firebase** — Auth, Firestore, Functions, Storage, FCM
- **Gemini 2.0 Flash** — AI analysis engine
- **ML Kit** — OCR for offer letters
- **FL Chart** — Analytics visualizations
- **Flutter Animate** — Premium micro-animations

---

## 📝 Environment Notes

> ⚠️ The `google-services.json` in this repo contains the real Firebase project config.  
> You **must** add your own Android SHA-1 fingerprint in the Firebase Console for Google Sign-In to work.

> ⚠️ The Gemini API key is stored server-side in Firebase Cloud Functions config — never hardcoded in the app.

---

*Built with ❤️ for India's digital safety*
