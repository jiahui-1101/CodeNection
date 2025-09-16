import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 需要加依赖

class HotlinePage extends StatelessWidget {
  const HotlinePage({super.key});

  // 拨打电话功能
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Hotline",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8EB9D4),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ContactCard(
            title: "Bahagian Keselamatan UTM",
            phone: "07-553 0014",
            onTap: () => _makePhoneCall("075530014"),
          ),
          ContactCard(
            title: "Pusat Kesihatan UTM",
            phone: "07-553 0999",
            onTap: () => _makePhoneCall("075530999"),
          ),
          ContactCard(
            title: "Unit OSHE (Keselamatan & Kesihatan Pekerjaan)",
            phone: "07-553 1886",
            onTap: () => _makePhoneCall("075531886"),
          ),
          ContactCard(
            title: "Balai Polis Taman Universiti",
            phone: "07-520 3129",
            onTap: () => _makePhoneCall("075203129"),
          ),
          ContactCard(
            title: "Balai Polis Skudai",
            phone: "07-556 1222",
            onTap: () => _makePhoneCall("075561222"),
          ),
          ContactCard(
            title: "Balai Polis Senai",
            phone: "07-599 1222",
            onTap: () => _makePhoneCall("075991222"),
          ),
          ContactCard(
            title: "Balai Bomba Pulai, Taman Universiti",
            phone: "07-520 4144",
            onTap: () => _makePhoneCall("075204144"),
          ),
          ContactCard(
            title: "Balai Bomba Kulai",
            phone: "07-663 4444",
            onTap: () => _makePhoneCall("076634444"),
          ),
          ContactCard(
            title: "Pusat Kesihatan Taman Universiti",
            phone: "07-521 6800",
            onTap: () => _makePhoneCall("075216800"),
          ),
          ContactCard(
            title: "Hospital Kulai",
            phone: "07-662 3333",
            onTap: () => _makePhoneCall("076623333"),
          ),
        ],
      ),
    );
  }
}

class ContactCard extends StatelessWidget {
  final String title;
  final String phone;
  final String? description;
  final VoidCallback? onTap; // 新增点击事件

  const ContactCard({
    super.key,
    required this.title,
    required this.phone,
    this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: ListTile(
        leading: const Icon(Icons.phone, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: description != null ? Text(description!) : null,
        trailing: Text(
          phone,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap, // 点卡片直接拨号
      ),
    );
  }
}
