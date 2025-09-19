import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<String?> showDeactivationDialog(
  BuildContext context,
  TextEditingController pinController,
  String safePin,
  String duressPin,
  AudioPlayer audioPlayer, {
  required String alertId,
  required Future<void> Function()? onDeactivate,
}) async {
  return showDialog<String>(
    context: context,
    // 用户点击弹窗外部无法关闭
    barrierDismissible: false,
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
          onPressed: () => Navigator.of(dialogContext).pop(), // Cancel 按钮保持不变
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            final enteredPin = pinController.text;
            pinController.clear(); // 清空输入框

            if (enteredPin == safePin) {
              // ✅ Safe PIN
              await audioPlayer.stop();
              await FirebaseFirestore.instance
                  .collection('alerts')
                  .doc(alertId)
                  .update({'status': 'cancelled'});
              if (onDeactivate != null) await onDeactivate();
              
              // 只关闭弹窗，并返回 'safe' 结果
              Navigator.of(dialogContext).pop('safe');

            } else if (enteredPin == duressPin) {
              // ⚠️ Duress PIN
              await audioPlayer.stop();
              final alertRef = FirebaseFirestore.instance.collection('alerts').doc(alertId);
              await alertRef.set(
                {'duress': true, 'status': 'pending'},
                SetOptions(merge: true),
              );

              // 只关闭弹窗，并返回 'duress' 结果
              Navigator.of(dialogContext).pop('duress');

            } else {
              // ❌ Wrong PIN - 不关闭弹窗，只提示错误
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.red,
                content: Text("❌ Incorrect PIN."),
              ));
            }
          },
          child: const Text("Confirm"),
        ),
      ],
    ),
  );
}