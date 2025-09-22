# JustBrightForUTM :sunny: 
<p align="center">
  <img src="assets/images/utmbright logo.jpg" width="150" hspace="20">
</p>

## Table of Contents
- [Track & Problem Statement](#track--problem-statement--mag_right)
- [Introduction](#introduction--mega)
- [Core Features](#core-features--star2)
- [Technical Stack](#-technical-stack--computer)
- [Usage](#usage--fire)
- [Setup Guide](#setup-guide--memo)
- [Documentation](#-documentation)
- [Contributors](#-contributors)

---
## Track & Problem Statement  :mag_right:
**Track:** CodeNection 2025-Track 2: Campus Safety App.

**Problem Statement:** Current safety infrastructure often lacks comprehensive coverage, real-time responsiveness, and accessibility features that address the diverse needs of the campus community, leaving gaps in protection and support.  

##  Introduction  :mega:
**JustBrightForUTM** is a *Smart Campus Mobility & Safety Companion* designed to enhance student safety and mobility.  
Our app addresses the fundamental challenge of *fear, safety, and accessibility* on campus by combining real-time mobility assistance with intelligent safety features.  

The app delivers its value through **three main features**:  

1. **Intelligent Navigation & Community Mobility**  
2. **The Ultimate SOS Button**  
3. **Community Safety Ecosystem**  



##  Core Features  :star2:

#### 1. Intelligent Navigation & Community Mobility  
- **Intelligent Navigation**

    1. **Safe Route Algorithm** – Chooses routes based on streetlight coverage, security post proximity, and reported hotspots.  
    
- **Community Mobility**
    1. **"Let's Walk!" Mode** – Anonymous, temporary walking groups for safe companionship.
    2. **Virtual Safety Companion** – Plays pre-recorded supportive voice notes from family/friends.  


#### 2. The Ultimate SOS Button  :sos:
- **Stage 1: Smart Context Alert**  
    1. **Deterrent Mode (Single Tap)** – Loud alarm or customizable sound.  
    2. **Pre-Arming (Long Press)** – Opens emergency classification menu (Medical, Security, etc.).  
    3. **Precise Dispatch** – Sends GPS + emergency type to campus security.  
    4. **Failsafe:** Auto-escalates to high-priority if no selection in 5s.  

- **Stage 2: Live Guardian Mode**  :speaker:
    1. **One-Way Audio Stream** – Discreet live audio to campus security.  
    2. **Real-Time Feedback** – Dims screen + displays reassuring text ("Help is on the way").  
    3. **Ultimate Safeguard** – *Duress PIN* cancels visibly but secretly escalates alert.  


#### 3. Community Safety Ecosystem  :mailbox:
- **Incident Reporting** – For hazards & suspicious activity.  
- **Resources Hub** – Centralized emergency contacts & support channels.  



## Technical Stack  :computer:
- **Frontend** 

  - Flutter 
- **Backend** 
  - C++
  - Java
- **Database** 
  - MySQL
- **Other Integrations:**  
  - Google Maps API
  - Real-time Audio Streaming  
  - Push Notifications  


## Core Version  :fire:
1. Launch the app.  
2. Enter the current location and destination access navigation mode.  
3. Use *"Let's Walk!"* to walk in groups or let the app suggest safe routes.  
4. In emergencies, tap and hold the **SOS button** to activate alerts.  
5. Explore the **Safety Ecosystem** for reports, hotspots, and resources.  

## Setup Guide  :memo:
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

## Project Structure
```bash
CodeNection/
├── functions/
│   ├── index.js
│   ├── package.json
│   └── package-lock.json
├── lib/
│   ├── features/
│   │   ├── report/
│   │   └── sos_alert/
│   │       ├── guard_view/
│   │       └── service/
│   ├── models/
│   ├── pages/
│   ├── widgets/
│   │   ├── AlertDeactivation.dart
│   │   ├── AppDrawer.dart
│   │   └── BlinkingIcon.dart
│   └── main.dart
├── assets/
├── android/
├── ios/
└── pubspec.yaml
```
## Documentation  
- **Demo / Walkthrough:** https://youtu.be/3rg5cUewwSQ
- **Tech Stack:** Flutter :heavy_plus_sign: C++/Dart :heavy_plus_sign: MySQL 

## Contributors  
- Team **JustBrightForUTM**

  -   Lee Mei Shuet
  -   Loh Su Ting
  -   Wong Jia Hui
  -   Wong Zi Qi



