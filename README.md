# 🚀 Apex-Nexus: AI-Powered Fintech Suite

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Next-black?style=for-the-badge&logo=next.js&logoColor=white" alt="Next.js" />
  <img src="https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white" alt="Firebase" />
  <img src="https://img.shields.io/badge/Google%20Gemini-8E75B2?style=for-the-badge&logo=google%20gemini&logoColor=white" alt="Gemini AI" />
</p>

**Apex-Nexus** is a cutting-edge, professional-grade cryptocurrency portfolio application. It features real-time market polling, a robust mock trading engine, and dynamic **Gemini AI** portfolio reviews. The application is built using a modern decoupled architecture: a **Flutter + GetX** mobile client backed by a highly secure **Next.js + Firebase** REST API.

---

## 📸 Key Features

- **🔐 Auth & Security:** Secure Email/Password onboarding and Local Biometric Auth powered by **Firebase**.
- **📈 Real-Time Markets:** Live asset price aggregation via the **CoinGecko API** streaming directly to the dashboard.
- **💎 Glassmorphic UI:** A premium "Deep Dark" mode aesthetic featuring beautifully frosted, high-performance Glassmorphism.
- **🛠️ Mock Trading Engine:** Execute simulated Buy/Sell orders starting with a virtual **$10,000 balance** instantiated upon sign-up.
- **📊 Real-Time P&L:** Total Invested, Current Value, and individualized Asset ROI dynamically computed as market prices fluctuate.
- **🧠 AI Portfolio Advisor:** Powered by **Google Gemini 1.5 Flash**, the app analyzes your explicit holdings to generate custom strategic investment advice.
- **📑 Transaction Ledger:** Immutable, granular transaction history permanently logged to Firestore sub-collections for audit-ready records.

---

## 🛠️ Tech Stack

### **Frontend (Mobile App)**
- **Framework:** Flutter (Dart)
- **State Management:** GetX (Reactive Architecture)
- **Charting Engine:** fl_chart & candlesticks
- **Biometrics:** local_auth integration

### **Backend (RESTful API)**
- **Framework:** Next.js 15+ (TypeScript) & App Router
- **Database:** Google Cloud Firestore (NoSQL)
- **LLM Integration:** @google/generative-ai (Gemini SDK)
- **Validation:** Zod schemas for type-safe API requests

---

## 🚀 Getting Started

This repository is structured as a Monorepo. You will need a Firebase project and a Gemini API Key to run the full suite.

### 1. Backend Setup (`/backend`)
The backend securely executes trades, manages the Firebase Admin SDK, and interfaces with Gemini.

1. `cd backend`
2. `npm install`
3. Create a `.env` file and provide your **GEMINI_API_KEY**.
4. **Firebase Admin SDK:** Download your service account JSON from the Firebase Console, rename it to `service-account.json`, and place it in the root of the `/backend` folder.
5. `npm run dev` to start the server on `localhost:3000`.

### 2. Frontend Setup (`/frontend`)
The Flutter client manages the local state and the premium UI components.

1. `cd frontend`
2. `flutter pub get`
3. **Firebase Mobile Setup:** Register your apps in the Firebase Console and place the configuration files:
   - Android: `google-services.json` in `/android/app/`
   - iOS: `GoogleService-Info.plist` in `/ios/Runner/`
4. Connect a device/emulator and run: `flutter run`.

---

## 🛡️ Firestore Architecture & Security Rules

To ensure secure data isolation, copy the following into your **Firebase Console -> Firestore -> Rules**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Wildcard applies read/write privileges strictly to the owner's Auth credential.
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
