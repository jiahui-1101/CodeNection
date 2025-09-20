class SafetyManualContent {
  // Fire Safety Section
  static const String fireSafetyTitle = "🔥 Fire Safety";
  static const String fireSafety = """
If you detect a fire: 🔥

1. 🔊 **Sound the alarm:** Alert others immediately.
2. 🚶 **Evacuate calmly:** Use stairs, not elevators.
3. 🚪 **Close doors behind you:** This helps contain the fire.
4. 🚷 **Do not re-enter:** Once outside, stay out.
5. 📞 **Call emergency services (999/local emergency number):** Provide your exact location.
6. 🐢 **Crawl low under smoke:** Smoke rises, so staying low helps you see and breathe.
7. 🔥 **"Stop, Drop, and Roll"** if your clothes catch fire.
8. 🚪 **Know your exits:** Always be aware of two ways out.
""";

  // Medical Emergency Section
  static const String medicalEmergencyTitle = "🏥 Medical Emergency";
  static const String medicalEmergency = """
In a medical emergency: 🚑

1. 👀 **Assess the situation:** Ensure personal safety first.
2. 📞 **Call emergency services (999/local emergency number):** Clearly state the emergency, location, and condition of the person.
3. 🚑 **Do not move the person** unless they are in immediate danger.
4. 🩹 **Provide basic first aid** if you are trained and it's safe to do so (e.g., CPR, controlling bleeding).
5. 🤝 **Stay with the person:** Offer reassurance until help arrives.
6. 👔 **Loosen tight clothing** around the neck for easier breathing.
7. 🚫 **Do not give food or drink** to an unconscious person or someone with difficulty swallowing.
""";

  // General Safety Section
  static const String generalSafetyTitle = "📋 General Safety Tips";
  static const String generalSafety = """
General Emergency Safety Tips: 🛡️

1. 😌 Stay calm and assess the situation.
2. 📢 Alert authorities immediately.
3. 👮 Follow instructions from emergency personnel.
4. 🚪 Know your emergency exits and assembly points.
5. 📋 Keep important emergency contacts readily available.
""";

  // Get all content as a map for easy access
  static Map<String, Map<String, String>> get allContent {
    return {
      'fire': {
        'title': fireSafetyTitle,
        'content': fireSafety,
      },
      'medical': {
        'title': medicalEmergencyTitle,
        'content': medicalEmergency,
      },
      'general': {
        'title': generalSafetyTitle,
        'content': generalSafety,
      },
    };
  }

  // Get formatted content for display
  static List<Map<String, String>> get formattedContent {
    return [
      {
        'title': fireSafetyTitle,
        'content': fireSafety,
        'icon': '🔥', // Fire icon
      },
      {
        'title': medicalEmergencyTitle,
        'content': medicalEmergency,
        'icon': '🏥', // Hospital icon
      },
      {
        'title': generalSafetyTitle,
        'content': generalSafety,
        'icon': '📋', // Clipboard icon
      },
    ];
  }
}