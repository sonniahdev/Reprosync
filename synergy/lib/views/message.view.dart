import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class MessageScreen extends StatefulWidget {
  final String doctorId;
  final String patientId;

  const MessageScreen({super.key, required this.doctorId, required this.patientId});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _userUid;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userUid = prefs.getString('user_uid');
    _userRole = prefs.getString('user_role');
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _userUid == null) return;
    await FirebaseFirestore.instance.collection('messages').add({
      'patientId': _userUid,
      'doctorId': widget.doctorId,
      'content': _messageController.text,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
    _messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message sent!'),
        backgroundColor: Color(0xFFff6b9d),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Doctor'),
        backgroundColor: const Color(0xFFff6b9d),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('patientId', isEqualTo: widget.patientId)
                  .where('doctorId', isEqualTo: widget.doctorId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(message['content'] ?? 'No message'),
                      subtitle: Text(
                        message['timestamp'] != null
                            ? DateTime.fromMillisecondsSinceEpoch(
                                    message['timestamp'].millisecondsSinceEpoch)
                                .toString()
                            : 'Unknown time',
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: const Color(0xFFff6b9d),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}