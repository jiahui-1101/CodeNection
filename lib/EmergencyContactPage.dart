import 'package:flutter/material.dart';

class EmergencyContactPage extends StatelessWidget {
  const EmergencyContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Emergency Contacts",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8EB9D4),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ContactCard(
            title: "Bahagian Keselamatan UTM",
            phone: "07-55 30014",
          ),
          ContactCard(
            title: "Pusat Kesihatan UTM",
            phone: "07-55 30999",
          ),
          ContactCard(
            title: "Unit Persekitaran, Keselamatan & Kesihatan Pekerjaan (OSHE)",
            phone: "07-55 31886",
          ),
          ContactCard(
            title: "Balai Polis Taman Universiti",
            phone: "07-520 3129",
          ),
          ContactCard(
            title: "Balai Polis Skudai",
            phone: "07-556 1222",
          ),
          ContactCard(
            title: "Balai Polis Senai",
            phone: "07-599 1222",
          ),
          ContactCard(
            title: "Balai Bomba Pulai, Taman Universiti",
            phone: "07-520 4144",
          ),
          ContactCard(
            title: "Balai Bomba Kulai",
            phone: "07-663 4444",
          ),
          ContactCard(
            title: "Pusat Kesihatan Taman Universiti",
            phone: "07-521 6800",
          ),
          ContactCard(
            title: "Hospital Kulai",
            phone: "07-662 3333",
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

  const ContactCard({
    super.key,
    required this.title,
    required this.phone,
    this.description, 
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
        subtitle: description != null ? Text(description!) : null, // 
        trailing: Text(
          phone,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
