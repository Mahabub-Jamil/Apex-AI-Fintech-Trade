# 🚀 Apex AI Fintech Trade

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Next-black?style=for-the-badge&logo=next.js&logoColor=white" alt="Next.js" />
  <img src="https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white" alt="Firebase" />
  <img src="https://img.shields.io/badge/Google%20Gemini-8E75B2?style=for-the-badge&logo=google%20gemini&logoColor=white" alt="Gemini AI" />
</p>

**Apex AI Fintech Trade** is a high-performance, AI-driven cryptocurrency trading simulator built with a modern full-stack architecture. It bridges the gap between real-time market data and artificial intelligence, providing users with a safe environment to practice trading while receiving personalized insights from Google Gemini AI.

---

## 💎 Core Features

* **🧠 Intelligent AI Sentiment:** Leverages **Gemini 1.5 Flash** to analyze live market trends and provide Bullish/Bearish sentiment analysis.
* **💹 Real-Time Market Ticker:** Streams live price data for top cryptocurrencies via the **CoinGecko API**.
* **💰 Paper Trading Simulator:** New users are instantiated with a **$10,000 virtual balance** in **Cloud Firestore** to execute trades without financial risk.
* **📊 Dynamic Portfolio Analytics:** Features interactive **Pie Charts** and **Performance Graphs** that recalculate net worth in real-time as market prices fluctuate.
* **🛡️ Secure Authentication:** Robust user onboarding flow powered by **Firebase Auth**, ensuring secure access to personal trading ledgers.
* **⚡ Next.js Backend:** A scalable server-side architecture using **Turbopack** for optimized API routing and AI model management.

---

## 🛠️ Technical Stack

### **Frontend (Mobile)**
* **Framework:** Flutter (Android/iOS)
* **State Management:** GetX (Reactive architecture)
* **UI/UX:** Glassmorphism Design, Custom Shimmer Effects, and Responsive Layouts

### **Backend & Infrastructure**
* **Server:** Next.js 15+ with TypeScript
* **AI Engine:** Google Generative AI (Gemini SDK)
* **Database:** Google Cloud Firestore (NoSQL)
* **Security:** Firebase Security Rules for user-specific data isolation

---

## 📂 Architecture Overview

```bash
├── frontend/               # Flutter Mobile Application
│   ├── lib/
│   │   ├── controllers/    # Business logic & API handlers (GetX)
│   │   ├── models/         # Data structures for Coins & Users
│   │   ├── screens/        # UI Layers (Hub, Auth, Portfolio)
│   │   └── widgets/        # Reusable Glassmorphic components
└── backend/                # Next.js API Services
    ├── src/app/api/        # Serverless functions for AI & Trading
    └── .env                # Environment configuration
