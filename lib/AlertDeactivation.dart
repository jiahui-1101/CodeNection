import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<String?> showDeactivationDialog( // 1. 修改返回类型为 String?
  BuildContext context,
  TextEditingController pinController,
  String safePin,
  String duressPin,
  AudioPlayer audioPlayer, {
  required String alertId,
  required Future<void> Function()? onDeactivate,
}) async {
  // 2. 修改 showDialog 的返回类型
  return showDialog<String>(
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
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(), // 只关闭对话框，不返回值
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            final enteredPin = pinController.text;

            if (enteredPin == safePin) {
              // ✅ Safe PIN → 真取消
              await audioPlayer.stop();
              await FirebaseFirestore.instance
                  .collection('alerts')
                  .doc(alertId)
                  .update({'status': 'cancelled'});

              if (onDeactivate != null) await onDeactivate();

              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.green,
                content: Text("✅ Alert genuinely cancelled."),
              ));
              // 3. 返回 'safe' 结果
              Navigator.of(dialogContext).pop('safe');
            } else if (enteredPin == duressPin) {
              // ⚠️ Duress PIN → 保留 alert
              await audioPlayer.stop();

              final alertRef =
                  FirebaseFirestore.instance.collection('alerts').doc(alertId);

              final alertSnap = await alertRef.get();
              if (!alertSnap.exists || alertSnap.data()?['duress'] != true) {
                await alertRef.set({'duress': true, 'status': 'pending'},
                    SetOptions(merge: true));
              }

              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.orange,
                content: Text(
                    "✅ Alert appears cancelled. Security notified of duress."),
              ));
              // 4. 返回 'duress' 结果
              Navigator.of(dialogContext).pop('duress');
            } else {
              // ❌ Wrong PIN
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.red,
                content: Text("❌ Incorrect PIN."),
              ));
              // 错误密码时不关闭对话框
            }
          },
          child: const Text("Confirm"),
        ),
      ],
    ),
  );
}