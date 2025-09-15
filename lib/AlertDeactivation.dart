import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void showDeactivationDialog(
  BuildContext context,
  TextEditingController pinController,
  String safePin,
  String duressPin,
  AudioPlayer audioPlayer,
) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text("Enter Deactivation PIN"),
      content: TextField(
        controller: pinController,
        keyboardType: TextInputType.number,
        obscureText: true,
        decoration: const InputDecoration(hintText: "4-digit PIN"),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Cancel")),
        TextButton(
          child: const Text("Confirm"),
          onPressed: () {
            final enteredPin = pinController.text;
            Navigator.of(dialogContext).pop();

            if (enteredPin == safePin) {
              audioPlayer.stop(); // Use the passed audioPlayer

              // Navigate back from GuardianModeScreen
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  backgroundColor: Colors.green,
                  content: Text("✅ Alert genuinely cancelled.")));
            } else if (enteredPin == duressPin) {
              audioPlayer.stop(); // Use the passed audioPlayer
              // Navigate back from GuardianModeScreen
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  backgroundColor: Colors.orange,
                  content: Text("✅ Alert *appears* cancelled. Security has been notified of duress.")));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  backgroundColor: Colors.red,
                  content: Text("❌ Incorrect PIN.")));
            }
          },
        ),
      ],
    ),
  );
}