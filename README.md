# JustBrightForUTM ☀️  
<p align="center">
  <img src="assets/images/utmbright logo.jpg" width="150" hspace="20">
</p>  

## Table of Contents
- [Track & Problem Statement](#track--problem-statement-mag_right)  
- [Introduction](#introduction-mega)  
- [Core Features](#core-features-star2)  
- [Technical Stack](#technical-stack-computer)  
- [Usage](#usage-fire)  
- [Setup Guide](#setup-guide-memo)  
- [Project Structure](#project-structure)  
- [Documentation](#documentation-books)  
- [Contributors](#contributors-)  
- [System Architecture](#system-architecture)  

---

## Track & Problem Statement :mag_right:  
**Track:** CodeNection 2025 — Track 2: Campus Safety App  

**Problem Statement:**  
Universities often face **gaps in safety infrastructure** — from poor real-time responsiveness during emergencies, to a lack of inclusive mobility tools for students walking alone at night. Current systems are fragmented, reactive, and not student-centric.  

---

## Introduction :mega:  
**JustBrightForUTM** is a **Smart Campus Mobility & Safety Companion** built to empower students with confidence and protection on campus.  

Our mission is to eliminate the *fear of walking alone*, provide **instant emergency response**, and foster a **community-driven safety ecosystem**.  

The app delivers its value through **three main pillars**:  
1. **Intelligent Navigation & Community Mobility**  
2. **The Ultimate SOS Button**  
3. **Community Safety Ecosystem**  

---

## Core Features :star2:  

### 1. Navigation & Community Mobility  
- **Navigation**  
  1. **Alternative Route Calculation** 
       
     - Provides **estimated time of arrival (ETA)** so users can plan their journey more confidently.  
     - Offers **turn-by-turn navigation guidance**, ensuring users stay on the correct path at all times.  
     - Suggests **alternative routes** if the primary path is blocked, longer than expected, or if the user prefers a different option.   
  2. **Walk Alone Mode** 1️⃣🚶
     - AI Chat + Virtual Companion for reassurance.  
     - Option to play **pre-recorded family/friends’ voices** (embedded in app).  

- **Community Mobility**  
  3. **“Let’s Walk!” Mode** 2️⃣🚶🚶🚶🚶🚶

     - **Navigation-based Matching** – pairs users heading in the *same or similar direction* using the route algorithm.
     - Temporary anonymous walking groups.   
     - In-app chat before and during the walk.  
     - *Safe Arrival Check-ins* for accountability.   ?????？


### 2. The Ultimate SOS Button 🆘  
- **Stage 1: Smart Context Alert**  
  1. **Deterrent Mode (Single Tap)** – Loud alarm or customizable sound.  
  2. **Pre-Arming (Long Press)** – Emergency classification menu: Medical, Security, Fire Hazard, etc.  
  3. **Precise Dispatch** – Sends **GPS + emergency type** to campus security.  
  4. **Failsafe** – If no input in **5s**, escalates to **high-priority alert**.  

- **Stage 2: Live Guardian Mode :speaker:**  
  1. **One-Way Audio Stream** – Live audio feed to campus security.  
  2. **Real-Time Feedback** – Provides discreet reassurance to the user once an SOS alert is triggered.  
     - The screen **dims automatically** to avoid drawing attention.  
     - Displays a calming confirmation message such as *“Help is on the way”*.  
     - Shows the **estimated arrival time (ETA) of responders**
     - Display **real-time distance between the user and the assigned guard/security personnel**, giving the user confidence that help is approaching.
  3. **Ultimate Safeguard (Duress PIN)** – Fake cancel PIN that secretly escalates the alert.  

- **Manual Safety Guides**  
  - Quick instructions for **fire evacuation** and **medical emergencies**.  

### 3. Community Safety Ecosystem 📬  
- **Incident Reporting**  
  - **Report hazards** or suspicious activity with text, photo, or audio.  
  - **Status Tracking**: Pending → In Review → Resolved.  
  - **Auto-Reminder** if no feedback in 24h.  

- **Guard/Admin Dashboard**  
  - Categorized reports for faster action.  
  - Security can provide feedback directly to users.  

- **Campus News & Alerts**  
  - Scrollable, pinned safety news.  
  - **Live Feed** – Displays a record of the user’s **personal safety activity history**, including:  
    - Safe arrivals logged after walks.  
    - Participation in group walks.  
    - Submitted incident reports and their status updates.  
    - Emergency alerts triggered with resolution status updates.

- **Resources Hub**  
  - Emergency contacts & support channels in one place.  

### 4. Duress PIN  
- An **alternate login PIN** that appears to cancel or unlock the app normally, but secretly **triggers a silent emergency alert** to campus security.  

- Useful in situations where the user is under **duress or threat** and cannot openly call for help (e.g., being forced to cancel an alert, unlock the app, or show compliance).  
- Once entered, the system:  
  1. Sends a **high-priority distress signal** with GPS location.  
  2. Optionally activates **Live Guardian Mode** (one-way audio streaming).  
  3. Keeps the interface looking normal to avoid suspicion.  

### 5. Hotlines  & Resources Hub
- One-tap quick access to:  
  - Campus Security  
  - Police  
  - Fire & Rescue  
  - Medical Services  
  - Emergency contacts


---

## Technical Stack :computer:  
- **Frontend**  
  - Flutter  

- **Backend**  
  - Firebase (Cloud Functions, Firestore, Authentication)  

- **Integrations**  
  - Google Maps Directions API (routing + ETA)  
  - Google Places API (location points)  
  - Google Geocoding API (address translation)  
  - Real-Time Audio Streaming  
  - Push Notifications (FCM)  
  - Gemini Developer Key (AI assistance)  

---

## Usage :fire:   

1. **Launch the App**  
   1. Open *JustBrightForUTM* on your device to access all safety and mobility features.  

2. **Start Navigation Mode**  
   1. Enter your **current location** and **destination**.  
      - The app calculates routes using the **Google Directions API**, showing **ETA, turn-by-turn guidance, and alternative paths**.  

3. **Choose Your Mobility Option**  
   1. **“Let’s Walk!” Mode** 
      - Join temporary group walks with nearby verified users heading in a similar direction.  
   2. **Walk Alone Mode** 
      - Enable **AI Chat + Virtual Companion** for reassurance
      - Play **pre-recorded family/friend voices** during the walk.  

4. **Activate the SOS Button (in Emergencies)**  
   1.  **Single Tap** – Trigger a loud alarm to deter threats.  
   2.  **Long Press** – Open the emergency classification menu (Medical, Security, Fire).  
   3.  Alerts are sent with **GPS location** and **emergency type** to campus security.  

5. **Access the Community Safety Ecosystem**  
   1.  **Incident Reporting** – Report hazards or suspicious activities.  
   2.  **Resources Hub** – Access emergency hotlines and guides.  
   3.  **Live Feed** – Review your personal safety history (safe arrivals, group walks, reports, triggered emergencies).  
   4. **News Board** – Read campus safety updates and pinned announcements.  

---

## Setup Guide :memo:   ???
You can run **JustBrightForUTM** in two ways:  

#### 1. Run on a Physical Device  
- **Android**  
  1. Connect your phone via USB and enable *Developer Options → USB Debugging*.  
  2. In project root, run:  
     ```bash
     flutter devices   # verify your phone is detected
     flutter run -d <device_id> --target=lib/demo.dart
     ```  
  3. The prototype will launch on your device.  

- **iOS (Mac required)**  
  1. Connect your iPhone and trust the computer.  
  2. Open the project in Xcode (`ios/Runner.xcworkspace`) to set your Apple Developer Team.  
  3. In terminal, run:  
     ```bash
     flutter run -d <device_id> --target=lib/demo.dart
     ```  

#### 2. Run on an Emulator / Simulator  
- **Android Emulator**  
  1. Open Android Studio → *Device Manager*.  
  2. Create and launch an emulator (Pixel recommended).  
  3. Run:  
     ```bash
     flutter run --target=lib/demo.dart
     ```  

- **iOS Simulator (macOS only)**  
  1. Open Xcode → *Open Developer Tool → Simulator*.  
  2. Run:  
     ```bash
     flutter run --target=lib/demo.dart
     ```  
---
## Project Structure ????
```bash
CodeNection/
├── .dart_tool/                 # Auto-generated Dart tools and configs
├── .idea/                      # IDE project settings (for Android Studio/IntelliJ)
├── android/                    # Native Android project files
├── assets/                     # App resources (media, fonts, images)
│   ├── audio/                  # Audio files (alerts, notifications, etc.)
│   ├── fonts/                  # Custom fonts
│   ├── images/                 # App images, icons, illustrations
│   └── music/                  # Background or companion music
├── build/                      # Generated build output (do not edit manually)
├── functions/                  # Firebase Cloud Functions (backend logic)
├── ios/                        # Native iOS project files
├── lib/                        # Main application source code
│   ├── features/               # Core features organized by module
│   │   ├── map/                # Navigation & map features
│   │   │   ├── group/          # Group walking mode ("Let's Walk!")
│   │   │   ├── individual/     # Individual navigation & solo routes
│   │   │   └── main_features/  # Shared/central navigation functions
│   │   ├── news/               # Campus/community news module
│   │   │   ├── staff_view/     # Staff/admin-facing news views
│   │   │   └── user_view/      # User-facing news views
│   │   ├── register/           # User registration and onboarding
│   │   ├── report/             # Safety incident reporting system
│   │   │   ├── report/         # Core reporting logic
│   │   │   ├── staff_view/     # Staff/admin view for reports
│   │   │   ├── user_view/      # User view for submitted reports
│   │   │   └── widgets/        # Shared widgets for reporting UI
│   │   └── sos_alert/          # Emergency SOS alert feature
│   │       ├── guard_view/     # Security/guard-side interface
│   │       ├── service/        # SOS backend services (API, logic)
│   │       └── user_view/      # User-side SOS alert interface
│   ├── firebase/               # Firebase integration helpers
│   ├── pages/                  # General app pages
│   │   ├── staff/              # Pages specific to staff/admin roles
│   │   └── user/               # Pages specific to end-users
│   └── main.dart               # App entry point
├── linux/                      # Native Linux project files
├── macos/                      # Native macOS project files
├── test/                       # Unit and widget tests
├── web/                        # Web build and assets
├── windows/                    # Native Windows project files
├── .firebaserc                 # Firebase project configuration
├── .flutter-plugins-dependencies # Auto-generated plugin dependencies
├── .gitignore                  # Git ignore rules
├── .metadata                   # Flutter project metadata
├── analysis_options.yaml       # Linter & code analysis rules
├── devtools_options.yaml       # Dart/Flutter DevTools options
├── firebase.json               # Firebase hosting/deployment settings
├── flutter/                    # Flutter-related configs
├── pubspec.lock                # Locked package versions (auto-generated)
├── pubspec.yaml                # Project dependencies & metadata
└── README.md                   # Project documentation
```

# Project Structure (Quick Overview)
```
CodeNection/
├── android/        # Android native files
├── ios/            # iOS native files
├── web/            # Web build
├── windows/        # Windows native files
├── macos/          # macOS native files
├── linux/          # Linux native files
├── assets/         # Media (audio, fonts, images, music)
├── build/          # Build output
├── functions/      # Firebase Cloud Functions (backend)
├── lib/            # Main Flutter app code
│   ├── features/   # Core features (map, SOS, report, news, register)
│   ├── firebase/   # Firebase integrations
│   ├── pages/      # App pages (staff, user)
│   └── main.dart   # Entry point
├── test/           # Unit & widget tests
├── pubspec.yaml    # Dependencies & metadata
└── README.md       # Documentation
```
---
## Documentation  
- **Demo / Walkthrough:** https://youtu.be/3rg5cUewwSQ
- **Tech Stack:** Flutter :heavy_plus_sign: Firebase :heavy_plus_sign: MySQL 
---
## Contributors  
- Team **JustBrightForUTM**

      🙋🏻‍♀️Lee Mei Shuet
      🙆🏻‍♀️Loh Su Ting
      🧏🏻‍♀️Wong Jia Hui
      💁🏻‍♀️Wong Zi Qi
---
## System Architecture
<p align="center">
  <img src="assets/images/systema.png">
</p>  


