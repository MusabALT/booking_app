import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserContactScreen extends StatefulWidget {
  const UserContactScreen({super.key});

  @override
  _UserContactScreenState createState() => _UserContactScreenState();
}

class _UserContactScreenState extends State<UserContactScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isEmpty) return;

    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to send a message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _firestore.collection('user_messages').add({
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Anonymous User',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'unread',
      });

      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Admin'),
        backgroundColor: Colors.blue.shade400,
      ),
      body: currentUser == null
          ? const Center(
              child: Text('Please log in to view and send messages.'),
            )
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('user_messages')
                        .where('userId', isEqualTo: currentUser.uid)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading messages.'),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No messages found.'),
                        );
                      }

                      var messages = snapshot.data!.docs;
                      return ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          var message = messages[index];
                          return Column(
                            children: [
                              _buildMessageBubble(
                                message: message['message'],
                                isMe: true,
                                timestamp: message['timestamp'],
                                status: message['status'],
                              ),
                              StreamBuilder<QuerySnapshot>(
                                stream: message.reference
                                    .collection('replies')
                                    .orderBy('timestamp')
                                    .snapshots(),
                                builder: (context, repliesSnapshot) {
                                  if (repliesSnapshot.hasError) {
                                    return const SizedBox.shrink();
                                  }

                                  if (!repliesSnapshot.hasData ||
                                      repliesSnapshot.data!.docs.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  var replies = repliesSnapshot.data!.docs;
                                  return Column(
                                    children: replies
                                        .map((reply) => _buildMessageBubble(
                                              message: reply['message'],
                                              isMe: false,
                                              timestamp: reply['timestamp'],
                                            ))
                                        .toList(),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isMe,
    Timestamp? timestamp,
    String? status,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue.shade100 : Colors.green.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (timestamp != null)
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                if (status != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    status == 'read' ? Icons.check_circle : Icons.pending,
                    color: status == 'read' ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue.shade400,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
