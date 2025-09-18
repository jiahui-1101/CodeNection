import 'package:flutter/material.dart';
import 'features/sos_alert/guard_page.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final List<Map<String, dynamic>> emergencyContacts = [
    {
      'name': 'Campus Security',
      'number': '03-8921 5555',
      'icon': Icons.security,
      'color': Colors.red,
    },
    {
      'name': 'Medical Emergency',
      'number': '03-8921 9999',
      'icon': Icons.local_hospital,
      'color': Colors.green,
    },
    {
      'name': 'Fire Department',
      'number': '03-8921 1111',
      'icon': Icons.fire_extinguisher,
      'color': Colors.orange,
    },
    {
      'name': 'IT Support',
      'number': '03-8921 2222',
      'icon': Icons.computer,
      'color': Colors.blue,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Contacts',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: emergencyContacts.length,
                itemBuilder: (context, index) {
                  final contact = emergencyContacts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: contact['color'],
                        child: Icon(contact['icon'], color: Colors.white),
                      ),
                      title: Text(contact['name']),
                      subtitle: Text(contact['number']),
                      trailing: IconButton(
                        icon: const Icon(Icons.call, color: Colors.green),
                        onPressed: () {
                          // Implement call functionality
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
      /*    ],
        ),
      ),
    );
  }
} */

           const SizedBox(height: 16),

            // 🚨 SOS Emergency Alert Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.warning, color: Colors.white, size: 28),
                label: const Text(
                  "SOS Emergency Alert",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // ⬅️ 跳转到 GuardPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GuardPage(guardId: "guard_001"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 