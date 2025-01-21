import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UserContactScreen extends StatefulWidget {
  const UserContactScreen({super.key});

  @override
  _UserContactScreenState createState() => _UserContactScreenState();
}

class _UserContactScreenState extends State<UserContactScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      String fileName =
          'user_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child(fileName);
      final uploadTask = await storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  void _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isEmpty && _selectedImage == null) return;

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

    setState(() {
      _isUploading = true;
    });

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      final messageData = {
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Anonymous User',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'unread',
      };

      if (imageUrl != null) {
        messageData['image_url'] = imageUrl;
      }

      await _firestore.collection('user_messages').add(messageData);

      _messageController.clear();
      setState(() {
        _selectedImage = null;
      });

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
    } finally {
      setState(() {
        _isUploading = false;
      });
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
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No messages found.'),
                        );
                      }

                      return ListView.builder(
                        reverse: true,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var messageDoc = snapshot.data!.docs[index];
                          var messageData =
                              messageDoc.data() as Map<String, dynamic>;

                          return Column(
                            children: [
                              _buildMessageBubble(
                                message: messageData['message'] ?? '',
                                imageUrl: messageData['image_url'],
                                isMe: true,
                                timestamp: messageData['timestamp'],
                                status: messageData['status'],
                              ),
                              StreamBuilder<QuerySnapshot>(
                                stream: messageDoc.reference
                                    .collection('replies')
                                    .orderBy('timestamp')
                                    .snapshots(),
                                builder: (context, repliesSnapshot) {
                                  if (!repliesSnapshot.hasData) {
                                    return const SizedBox.shrink();
                                  }

                                  return Column(
                                    children:
                                        repliesSnapshot.data!.docs.map((reply) {
                                      var replyData =
                                          reply.data() as Map<String, dynamic>;
                                      return _buildMessageBubble(
                                        message: replyData['message'] ?? '',
                                        imageUrl: replyData['image_url'],
                                        isMe: false,
                                        timestamp: replyData['timestamp'],
                                      );
                                    }).toList(),
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
    String? imageUrl,
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
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            if (imageUrl != null && message.isNotEmpty)
              const SizedBox(height: 8),
            if (message.isNotEmpty)
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
      child: Column(
        children: [
          if (_selectedImage != null)
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  height: 100,
                  width: 100,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => setState(() => _selectedImage = null),
                ),
              ],
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: _pickImage,
              ),
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
                child: _isUploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
