import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'emergency_contact_dialogs.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactList extends StatelessWidget {
  final User user;

  const EmergencyContactList({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final CollectionReference contactsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('emergency_contacts');

    return StreamBuilder<QuerySnapshot>(
      stream: contactsCollection
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildContactList(snapshot.data!.docs, context);
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contact_phone,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No emergency contacts",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Add your first emergency contact",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => EmergencyContactDialogs.showAddContactDialog(context, user),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              "Add Contact",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactList(List<DocumentSnapshot> contacts, BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        var contact = contacts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _ContactListItem(contact: contact),
        );
      },
    );
  }
}

class _ContactListItem extends StatelessWidget {
  final DocumentSnapshot contact;

  const _ContactListItem({required this.contact});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.blue[100],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          color: Colors.blue[800],
          size: 28,
        ),
      ),
      title: Text(
        contact.get('name') ?? 'No Name',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        contact.get('phone') ?? '',
        style: const TextStyle(fontSize: 14),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.phone, color: Colors.green[700]),
            onPressed: () => _makePhoneCall(contact.get('phone') ?? '', context),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue[700]),
            onPressed: () => EmergencyContactDialogs.showEditContactDialog(context, contact),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    final Uri url = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceAll(RegExp(r'\s+|-'), ''),
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not call $phoneNumber'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}