// lib/screens/admin/admin_chat_detail_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/models/user_model.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/utils/app_theme.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final UserModel parent;
  const AdminChatDetailScreen({super.key, required this.parent});

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage(String adminId) {
    if (_messageController.text.trim().isEmpty) return;

    // Path ke chat wali murid yang dituju
    final chatPath = _firestore
        .collection('chats')
        .doc(widget.parent.uid) // Gunakan UID wali murid sebagai ID dokumen chat
        .collection('messages');

    chatPath.add({
      'text': _messageController.text.trim(),
      'senderId': adminId, // ID pengirim adalah ID admin yang sedang login
      'senderRole': 'admin',
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Dapatkan ID admin yang sedang login
    final adminId =
        Provider.of<AuthProvider>(context, listen: false).userModel!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Chat dengan ${widget.parent.parentName}"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.parent.uid) // Baca dari dokumen chat milik wali murid
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                        "Belum ada percakapan dengan ${widget.parent.parentName}."),
                  );
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData =
                        messages[index].data() as Map<String, dynamic>;
                    
                    // Cek apakah pengirim pesan adalah admin
                    final bool isAdminSender = messageData['senderRole'] == 'admin';

                    return _buildMessageBubble(
                      text: messageData['text'] ?? '',
                      isFromAdmin: isAdminSender,
                    );
                  },
                );
              },
            ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ketik balasan...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none),
                      fillColor: Colors.grey[200],
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: () => _sendMessage(adminId),
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({required String text, required bool isFromAdmin}) {
    // Jika pesan dari admin, tampilkan di kanan. Jika dari user, di kiri.
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isFromAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Tampilkan avatar user jika pesan bukan dari admin
          if (!isFromAdmin) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.accentColor,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFromAdmin
                    ? AppTheme.primaryColor.withOpacity(0.9)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isFromAdmin ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          // Tampilkan avatar admin jika pesan dari admin
          if (isFromAdmin) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.support_agent, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}