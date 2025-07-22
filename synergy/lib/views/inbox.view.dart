import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  String? _userUid;
  String? _userRole;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userUid = prefs.getString('user_uid');
    _userRole = prefs.getString('user_role');
    if (_userUid != null) {
      _updateUnreadCount();
    }
  }

  Future<void> _updateUnreadCount() async {
    if (_userUid == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('patientId', isEqualTo: _userUid)
        .where('read', isEqualTo: false)
        .get();
    setState(() {
      _unreadCount = snapshot.docs.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Stack(
          children: [
            const Text('Inbox'),
            if (_unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFFff6b9d),
      ),
      body: _userUid == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('patientId', isEqualTo: _userUid)
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
                      onTap: () async {
                        await FirebaseFirestore.instance
                            .collection('messages')
                            .doc(messages[index].id)
                            .update({'read': true});
                        _updateUnreadCount();
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}