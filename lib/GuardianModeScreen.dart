import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class GuardianModeScreen extends StatelessWidget {   // long press then click any of 3 icon from sos button atau exceed 5s no response will enter 守护模式页面
  final String initialMessage;
  final AudioPlayer audioPlayer;   // ✅ 新增

  const GuardianModeScreen({
    super.key, 
    required this.initialMessage,
    required this.audioPlayer,
  });
  
  // “暗号”取消机制的对话框
  void _showDeactivationDialog(BuildContext context) {
    final pinController = TextEditingController();
    const safePin = "0000";    // 真实的安全密码
    const duressPin = "1234"; // 被胁迫时用的危险密码

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
              Navigator.of(dialogContext).pop(); // 关闭PIN输入框
              
              if (enteredPin == safePin) {
                audioPlayer.stop();  // ✅ 停止 alarm

                Navigator.of(context).pop(); // 关闭守护模式页面
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: Colors.green,
                    content: Text("✅ Alert genuinely cancelled.")));
              } else if (enteredPin == duressPin) {
                audioPlayer.stop();  // ✅ 停止 alarm
                Navigator.of(context).pop(); // 关闭守护模式页面
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    initialMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Help is on the way...",
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                ],
              ),
              const Center(
                // TODO: 这里未来可以换成实时地图
                child: Icon(Icons.shield_moon, color: Colors.white24, size: 150),
              ),
              ElevatedButton(
                onPressed: () => _showDeactivationDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade900,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Deactivate with PIN"),
              )
            ],
          ),
        ),
      ),
    );
  }
}