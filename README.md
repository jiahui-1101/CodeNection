# JustBrightForUTM :sunny: 
<p align="center">
  <img src="assets/images/utmbright logo.jpg" width="150" hspace="20">
</p>

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#project-description">Track & Problem Statement</a>
    </li>
    <li>
      <a href="#how-it-worked">Introduction</a>
    </li>
    <li>
      <a href="#objectives">Core Features</a>
    </li>
    <li>
      <a href="#technologies-used">Technical Stack</a>
    </li>
      <li>
      <a href="#setup-guide">Usage</a>
    </li>
    <li>
      <a href="#setup-guide">Setup Guide</a>
    </li>
      <li>
      <a href="#setup-guide">Documentation</a>
    </li>
      <li>
      <a href="#setup-guide">Contributors</a>
    </li>
  </ol>
</details>


##  Track & Problem Statement  :mag_right:
**Track:** CodeNection 2025-Track 2: Campus Safety App 
**Problem Statement:** *Current safety infrastructure often lacks comprehensive coverage, real-time responsiveness, and accessibility features that address the diverse needs of the campus community, leaving gaps in protection and support.*  

##  Introduction  :mega:
**JustBrightForUTM** is a *Smart Campus Mobility & Safety Companion* designed to enhance student safety and mobility.  
Our app addresses the fundamental challenge of *fear, safety, and accessibility* on campus by combining real-time mobility assistance with intelligent safety features.  

The app delivers its value through **three main features**:  

1. **Intelligent Navigation & Community Mobility**  
2. **The Ultimate SOS Button**  
3. **Community Safety Ecosystem**  



##  Core Features  :star2:

#### 1. Intelligent Navigation & Community Mobility  
- **Walking Mode**  :walking:
  - **"Let's Walk!"** – Anonymous, temporary walking groups for safe companionship.  
  - **Safe Route Algorithm** – Chooses routes based on streetlight coverage, security post proximity, and reported hotspots.  
  - **Virtual Safety Companion** – Plays pre-recorded supportive voice notes from family/friends.  
  - **One-Tap Flashlight** – Quick access flashlight inside the walking interface.  

- **Driving Mode**  :car:
  - **Campus Waze** – Live, community-sourced updates on closures, congestion, and campus events.


#### 2. The Ultimate SOS Button  :sos:
- **Stage 1: Smart Context Alert**  
  - **Deterrent Mode (Single Tap)** – Loud alarm or customizable sound.  
  - **Pre-Arming (Long Press)** – Opens emergency classification menu (Medical, Security, etc.).  
  - **Precise Dispatch** – Sends GPS + emergency type to campus security.  
  - **Failsafe:** Auto-escalates to high-priority if no selection in 5s.  

- **Stage 2: Live Guardian Mode**  :speaker:
  - **One-Way Audio Stream** – Discreet live audio to campus security.  
  - **Real-Time Feedback** – Dims screen + shows live security officer ETA & map.  
  - **Ultimate Safeguard** – *Duress PIN* cancels visibly but secretly escalates alert.  


#### 3. Community Safety Ecosystem  :mailbox:
- **Incident Reporting** – For hazards & suspicious activity.  
- **Safety Hotspot Map** – Real-time safety check-ins create a “safety weather map.”  
- **Resources Hub** – Centralized emergency contacts & support channels.  



## Technical Stack  :computer:
- **Frontend:** React Native / Flutter *(specify)*  
- **Backend:** Firebase / Node.js / Express *(specify)*  
- **Database:** Firestore / MySQL / PostgreSQL *(specify)*  
- **Other Integrations:**  
  - Maps API (Google Maps / OpenStreetMap)  
  - Real-time Audio Streaming  
  - Push Notifications  


## Usage  :fire:
1. Launch the app.  
2. Select **Walking Mode** or **Driving Mode** to access navigation mode.  
3. Use *"Let's Walk!"* to walk in groups or let the app suggest safe routes.  
4. In emergencies, tap and hold the **SOS button** to activate alerts.  
5. Explore the **Safety Ecosystem** for reports, hotspots, and resources.  

## Setup Guide :memo:
You can run **JustBrightForUTM** in two ways:  

#### 1. Run on a Physical Device  
- **Android**  
  1. Connect your phone via USB and enable *Developer Options → USB Debugging*.  
  2. In project root, run:  
     ```bash
     flutter devices   # verify your phone is detected
     flutter run -d <device_id>
     ```  
  3. The prototype will launch on your device.  

- **iOS (Mac required)**  
  1. Connect your iPhone and trust the computer.  
  2. Open the project in Xcode (`ios/Runner.xcworkspace`) to set your Apple Developer Team.  
  3. In terminal, run:  
     ```bash
     flutter run -d <device_id>
     ```  

#### 2. Run on an Emulator / Simulator  
- **Android Emulator**  
  1. Open Android Studio → *Device Manager*.  
  2. Create and launch an emulator (Pixel recommended).  
  3. Run:  
     ```bash
     flutter run
     ```  

- **iOS Simulator (macOS only)**  
  1. Open Xcode → *Open Developer Tool → Simulator*.  
  2. Run:  
     ```bash
     flutter run
     ```  

#### 3. Run from an APK (Android only)  
If you just want to test the app without Flutter SDK:  
1. Download the generated `.apk` from `build/app/outputs/flutter-apk/app-release.apk`.  
2. Transfer to your Android device.  
3. Open the file to install (you may need to enable *Install from Unknown Sources* in settings).  



## 📖 Documentation  
- **System Architecture:** [Insert link or diagram if available]  
- **Demo / Walkthrough:** [Add YouTube / Loom link if available]  
- **Technical Stack:** [List here – e.g., Flutter + Firebase, React Native, Node.js, etc.]  


## 👨‍💻 Contributors  
- Team **JustBrightForUTM**

  -   Lee Mei Shuet
  -   Loh Su Ting
  -   Wong Jia Hui
  -   Wong Zi Qi



