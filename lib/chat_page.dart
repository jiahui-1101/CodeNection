import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> partner;
  final String chatId;

  const ChatPage({super.key, required this.partner, required this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _currentUserId;
  late String _chatId;
  late Map<String, dynamic> _partner;
  Stream<QuerySnapshot>? _messagesStream;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('No user logged in');
      return;
    }
    _currentUserId = currentUser.uid;
    _chatId = widget.chatId;
    _partner = widget.partner;

    _initializeChat();
  }

  void _setError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  Future<void> _initializeChat() async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(_chatId).get();

      if (!chatDoc.exists) {
        // Create the chat if it doesn't exist
        await _firestore.collection('chats').doc(_chatId).set({
          'participants': [_currentUserId, _partner['uid']],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Fix any issues with participants
        final rawParticipants = chatDoc['participants'] as List<dynamic>? ?? [];
        
        // Filter out null values and ensure both users are in participants
        final validParticipants = rawParticipants
            .where((id) => id != null)
            .map((id) => id.toString())
            .toSet() // Use set to avoid duplicates
            .toList();
        
        // Add current user if not already in participants
        if (!validParticipants.contains(_currentUserId)) {
          validParticipants.add(_currentUserId);
        }
        
        // Add partner if not already in participants
        if (!validParticipants.contains(_partner['uid'])) {
          validParticipants.add(_partner['uid']);
        }
        
        // Update participants if needed
        if (validParticipants.length != rawParticipants.length || 
            rawParticipants.any((id) => id == null)) {
          await _firestore.collection('chats').doc(_chatId).update({
            'participants': validParticipants,
          });
        }
      }

      _setUpMessagesStream();
      setState(() => _isLoading = false);
    } catch (e) {
      _setError('Failed to initialize chat: $e');
    }
  }

  void _setUpMessagesStream() {
    _messagesStream = _firestore
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final message = _controller.text.trim();
    _controller.clear();

    try {
      await _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'text': message,
        'senderId': _currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('chats').doc(_chatId).update({
        'lastMessage': message,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  Widget _buildMessageBubble(DocumentSnapshot messageDoc) {
    final message = messageDoc.data() as Map<String, dynamic>;
    final isMe = message['senderId'] == _currentUserId;
    final timestamp = message['timestamp'] != null
        ? (message['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    final timeFormatted = DateFormat('HH:mm').format(timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Text(
                _getAvatarEmoji(_partner['email'] ?? ''),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          if (!isMe) const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    message['text'] ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeFormatted,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 6),
          if (isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              child: Text(
                _getAvatarEmoji(_auth.currentUser?.email ?? ''),
                style: const TextStyle(fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  String _getAvatarEmoji(String email) {
    if (email.isEmpty) return '👤';
    final hash = email.hashCode;
    final emojis = ['👤', '👨', '👩', '🧑', '👨‍💼', '👩‍💼', '🧑‍💼'];
    return emojis[hash.abs() % emojis.length];
  }

  String _getDisplayName(String email) {
    if (email.isEmpty) return 'Unknown';
    final namePart = email.split('@').first;
    return namePart
        .split('.')
        .map(
          (part) =>
              part.isEmpty ? part : part[0].toUpperCase() + part.substring(1),
        )
        .join(' ');
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                _errorMessage ?? 'An unknown error occurred',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
              if (_errorMessage?.contains('Failed to initialize chat') ?? false)
                const SizedBox(height: 20),
              if (_errorMessage?.contains('Failed to initialize chat') ?? false)
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    await _initializeChat();
                  },
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading chat...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final partnerEmail = _partner['email'] ?? 'Unknown';
    final partnerName = _getDisplayName(partnerEmail);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                _getAvatarEmoji(partnerEmail),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Online',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Start a conversation!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[50],
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}