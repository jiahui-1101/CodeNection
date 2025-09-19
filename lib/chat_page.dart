import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic>? partner;
  final String? chatId;

  const ChatPage({super.key, this.partner, this.chatId})
      : assert(
          partner != null || chatId != null,
          'Provide either partner or chatId',
        );

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
  Map<String, dynamic>? _partner; // made nullable for safety
  late Stream<QuerySnapshot> _messagesStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _currentUserId = _auth.currentUser?.uid ?? '';

    // Validate that we have either partner or chatId
    if (widget.chatId == null && widget.partner == null) {
      _showErrorAndNavigateBack();
      return;
    }

    // Set up chat ID and partner info
    if (widget.chatId != null) {
      _chatId = widget.chatId!;
      _loadChatInfo();
    } else if (widget.partner != null) {
      _partner = widget.partner!;
      // Generate a unique chat ID based on user IDs
      final List<String> userIds = [_currentUserId, _partner!['uid']];
      userIds.sort();
      _chatId = 'chat_${userIds.join("_")}';

      // Initialize chat if it doesn't exist
      _initializeChat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showErrorAndNavigateBack() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No chat information provided')),
      );
      Navigator.of(context).pop();
    });
  }

  Future<void> _initializeChat() async {
    // Check if chat already exists
    final chatDoc = await _firestore.collection('chats').doc(_chatId).get();

    if (!chatDoc.exists) {
      // Create a new chat document
      await _firestore.collection('chats').doc(_chatId).set({
        'participants': [_currentUserId, _partner?['uid']],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    }

    // Set up messages stream
    _setUpMessagesStream();
    setState(() => _isLoading = false);
  }

  Future<void> _loadChatInfo() async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(_chatId).get();
      if (chatDoc.exists) {
        final participants = chatDoc['participants'] as List<dynamic>;
        final partnerId = participants.firstWhere(
          (id) => id != _currentUserId,
          orElse: () => participants.isNotEmpty ? participants[0] : '',
        );

        final userDoc =
            await _firestore.collection('users').doc(partnerId.toString()).get();
        if (userDoc.exists) {
          setState(() {
            _partner = userDoc.data() as Map<String, dynamic>;
            _isLoading = false;
          });
          _setUpMessagesStream();
        } else {
          _showErrorAndNavigateBack();
        }
      } else {
        _showErrorAndNavigateBack();
      }
    } catch (e) {
      _showErrorAndNavigateBack();
    }
  }

  void _setUpMessagesStream() {
    setState(() {
      _messagesStream = _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots();
    });
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
                _getAvatarEmoji(_partner?['email'] ?? ''),
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
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
    final hash = email.hashCode;
    final emojis = ['👤', '👨', '👩', '🧑', '👨‍💼', '👩‍💼', '🧑‍💼'];
    return emojis[hash.abs() % emojis.length];
  }

  String _getDisplayName(String email) {
    final namePart = email.split('@').first;
    return namePart
        .split('.')
        .map((part) =>
            part.isEmpty ? part : part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _partner == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading chat...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final partnerEmail = _partner?['email'] ?? 'Unknown';
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
                      fontSize: 16, fontWeight: FontWeight.bold),
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
