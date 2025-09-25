import 'package:flutter/material.dart';
import 'package:hello_flutter/features/sos_alert/user_view/SafetyManualContent.dart'; 

void showSafetyManualDialog(BuildContext context, String initialMessage) {
  String title = '';
  String content = '';

  if (initialMessage.contains('Fire')) {
    title = "Fire Safety Guide";
    content = SafetyManualContent.fireSafety; 
  } else if (initialMessage.contains('Medical')) {
    title = "Medical Emergency Guide";
    content = SafetyManualContent.medicalEmergency; 
  } else {
    title = "General Safety Tips";
    content = SafetyManualContent.generalSafety; 
  }

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Text(
          content,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text("Close"),
        ),
      ],
    ),
  );
}